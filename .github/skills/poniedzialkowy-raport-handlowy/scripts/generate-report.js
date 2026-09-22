#!/usr/bin/env node
/*
 * Generuje poniedziałkowy przegląd handlowy: PDF (wg szablonu z
 * ../assets/szablon-raportu.md) i/lub proste zestawienie tabel w Excelu —
 * na żądanie, przez flagi CLI.
 *
 * Dane pobierane z reporting.vw_SalesWeekly przez ./query-data.sql
 * (6 recordsetów, ta sama logika wyboru tygodnia co w generate-report.sql).
 *
 * Pierwsze uruchomienie: skrypt sam wykrywa brak node_modules i uruchamia
 * `npm install` w tym folderze — nie trzeba nic instalować ręcznie.
 *
 * Konfiguracja połączenia — zmienne środowiskowe (domyślne jak w scripts/dw.sh):
 *   MSSQL_HOST      (domyślnie 127.0.0.1)
 *   MSSQL_PORT      (domyślnie 14330)
 *   MSSQL_DATABASE  (domyślnie RetailDW)
 *   MSSQL_SA_PASSWORD (domyślnie hasło deweloperskie z dw.sh)
 *   FONT_REGULAR / FONT_BOLD — ścieżki do TTF, jeśli domyślne (Arial) nie istnieją
 *
 * Insights: sekcja "Insights & Decyzje" w PDF wymaga interpretacji danych
 * przez analityka/agenta (SQL sam z siebie jej nie da — patrz SKILL.md).
 * Przekaż gotowe punkty plikiem JSON: { "insights": ["punkt 1", "punkt 2"] }.
 * Bez --insights sekcja zostaje pusta z przypomnieniem do uzupełnienia.
 *
 * Użycie:
 *   node generate-report.js [--pdf] [--xlsx] [--insights <plik.json>] [--out <folder>]
 *   (bez --pdf/--xlsx generowane są oba formaty)
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const SCRIPT_DIR = __dirname;
const QUERY_FILE = path.join(SCRIPT_DIR, 'query-data.sql');

// Wypełniane przez ensureDependencies() po weryfikacji/instalacji node_modules.
let sql, PDFDocument, ExcelJS;

function ensureDependencies() {
  const nodeModulesPath = path.join(SCRIPT_DIR, 'node_modules');
  const required = ['mssql', 'pdfkit', 'exceljs'];
  const missing = required.some((pkg) => !fs.existsSync(path.join(nodeModulesPath, pkg)));

  if (missing) {
    console.log('Pierwsze uruchomienie — brak zależności, instaluję (npm install)...');
    const result = spawnSync('npm', ['install'], { cwd: SCRIPT_DIR, stdio: 'inherit', shell: true });
    if (result.status !== 0) {
      throw new Error(`npm install nie powiodło się. Uruchom ręcznie "npm install" w ${SCRIPT_DIR}`);
    }
  }

  sql = require('mssql');
  PDFDocument = require('pdfkit');
  ExcelJS = require('exceljs');
}

function parseArgs(argv) {
  const args = { out: path.join(SCRIPT_DIR, 'out'), pdf: false, xlsx: false, insightsFile: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--out' && argv[i + 1]) {
      args.out = path.resolve(argv[i + 1]);
      i++;
    } else if (argv[i] === '--pdf') {
      args.pdf = true;
    } else if (argv[i] === '--xlsx' || argv[i] === '--excel') {
      args.xlsx = true;
    } else if (argv[i] === '--insights' && argv[i + 1]) {
      args.insightsFile = path.resolve(argv[i + 1]);
      i++;
    }
  }
  // Bez jawnych flag generujemy oba formaty (dotychczasowe zachowanie).
  if (!args.pdf && !args.xlsx) {
    args.pdf = true;
    args.xlsx = true;
  }
  return args;
}

function loadInsights(insightsFile) {
  if (!insightsFile) return [];
  const raw = JSON.parse(fs.readFileSync(insightsFile, 'utf8'));
  if (!Array.isArray(raw.insights)) {
    throw new Error(`Plik insights musi mieć postać { "insights": ["..."] }: ${insightsFile}`);
  }
  return raw.insights;
}

function findFont(envVar, candidates) {
  if (process.env[envVar] && fs.existsSync(process.env[envVar])) {
    return process.env[envVar];
  }
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

// Wbudowane fonty pdfkit (Helvetica) nie obsługują polskich znaków diakrytycznych.
function resolveFonts() {
  const regular = findFont('FONT_REGULAR', [
    'C:\\Windows\\Fonts\\arial.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ]);
  const bold = findFont('FONT_BOLD', [
    'C:\\Windows\\Fonts\\arialbd.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  ]);
  if (!regular || !bold) {
    throw new Error(
      'Nie znaleziono fontu z obsługą polskich znaków. Ustaw zmienne środowiskowe ' +
      'FONT_REGULAR i FONT_BOLD na ścieżki do plików .ttf (np. Arial lub DejaVu Sans).'
    );
  }
  return { regular, bold };
}

async function fetchData() {
  const config = {
    server: process.env.MSSQL_HOST || '127.0.0.1',
    port: parseInt(process.env.MSSQL_PORT || '14330', 10),
    database: process.env.MSSQL_DATABASE || 'RetailDW',
    user: process.env.MSSQL_SA_USER || 'sa',
    password: process.env.MSSQL_SA_PASSWORD || 'Workshop_Dev2026#',
    options: { encrypt: false, trustServerCertificate: true },
  };

  const queryText = fs.readFileSync(QUERY_FILE, 'utf8');
  const pool = await sql.connect(config);
  try {
    const result = await pool.request().query(queryText);
    const [meta, summary, changes, growth, decline, channels] = result.recordsets;
    return {
      meta: meta[0],
      summary: summary[0],
      changes,
      growth,
      decline,
      channels,
    };
  } finally {
    await pool.close();
  }
}

function pct(value) {
  if (value === null || value === undefined) return 'b/d';
  const sign = value > 0 ? '+' : '';
  return `${sign}${Number(value).toFixed(1)}%`;
}

function pln(value) {
  if (value === null || value === undefined) return 'b/d';
  return `${Number(value).toLocaleString('pl-PL', { maximumFractionDigits: 0 })} PLN`;
}

function fmtDate(d) {
  return new Date(d).toLocaleDateString('pl-PL');
}

const COLOR_HEADER_BG = '#2F5496';
const COLOR_HEADER_TEXT = '#FFFFFF';
const COLOR_ROW_ALT = '#F2F2F2';
const COLOR_POSITIVE = '#1E7B34';
const COLOR_NEGATIVE = '#B00020';
const COLOR_BORDER = '#CCCCCC';

function pctColor(value) {
  if (value === null || value === undefined) return 'black';
  return Number(value) >= 0 ? COLOR_POSITIVE : COLOR_NEGATIVE;
}

function buildPdf(data, outPath, fonts, insights) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const stream = fs.createWriteStream(outPath);
    doc.pipe(stream);
    stream.on('finish', resolve);
    stream.on('error', reject);

    doc.registerFont('Body', fonts.regular);
    doc.registerFont('Heading', fonts.bold);

    const pageLeft = doc.page.margins.left;
    const pageWidth = doc.page.width - pageLeft - doc.page.margins.right;

    // Rysuje tabelę z nagłówkiem, naprzemiennym tłem wierszy i opcjonalnym
    // kolorowaniem kolumn procentowych (pdfkit nie ma wbudowanych tabel).
    function drawTable(columns, rows, { colorPctColumn = null } = {}) {
      const startX = pageLeft;
      let y = doc.y;
      const rowHeight = 20;
      const totalWidth = columns.reduce((s, c) => s + c.width, 0);

      doc.rect(startX, y, totalWidth, rowHeight).fill(COLOR_HEADER_BG);
      doc.font('Heading').fontSize(9).fillColor(COLOR_HEADER_TEXT);
      let x = startX;
      columns.forEach((col) => {
        doc.text(col.header, x + 4, y + 6, { width: col.width - 8, align: col.align || 'left' });
        x += col.width;
      });
      y += rowHeight;

      doc.font('Body').fontSize(9);
      rows.forEach((row, idx) => {
        if (idx % 2 === 1) {
          doc.rect(startX, y, totalWidth, rowHeight).fill(COLOR_ROW_ALT);
        }
        x = startX;
        columns.forEach((col) => {
          const value = col.value(row);
          const isColored = colorPctColumn === col.key;
          doc.fillColor(isColored ? pctColor(row[col.key]) : 'black');
          doc.text(value, x + 4, y + 6, { width: col.width - 8, align: col.align || 'left' });
          x += col.width;
        });
        y += rowHeight;
      });

      doc.rect(startX, doc.y, totalWidth, y - doc.y).strokeColor(COLOR_BORDER).stroke();
      doc.fillColor('black');
      doc.x = startX;
      doc.y = y + 8;
    }

    const wow = data.changes.find((c) => c.Label === 'WoW');
    const yoy = data.changes.find((c) => c.Label === 'YoY');

    doc.font('Heading').fontSize(18).text(`Przegląd handlowy — tydzień ${data.meta.CurrentWeek}`);
    doc.font('Body').fontSize(10)
      .text(`Okres: ${fmtDate(data.meta.WeekStart)} – ${fmtDate(data.meta.WeekEnd)}`)
      .text(`Data raportu: ${new Date().toLocaleString('pl-PL')}`);
    doc.moveDown();

    doc.font('Heading').fontSize(13).fillColor('black').text('Podsumowanie wykonania');
    doc.font('Body').fontSize(11).text(
      `Sprzedaż netto ubiegłego tygodnia wyniosła ${pln(data.summary.NetAmount)}, ` +
      `co stanowi ${pct(wow && wow.PctChange)} zmianę tygodniowo i ${pct(yoy && yoy.PctChange)} rok do roku. ` +
      `Liczba transakcji: ${data.summary.Transactions ?? 'b/d'}. Średni koszyk: ${pln(data.summary.AvgBasket)}.`,
      { align: 'justify' }
    );
    doc.moveDown();

    const changeColumns = [
      { key: 'Category', header: 'Kategoria', width: pageWidth * 0.4, value: (r) => `${r.Category} (${r.Channel})` },
      { key: 'PctChange', header: 'Zmiana', width: pageWidth * 0.2, align: 'right', value: (r) => pct(r.PctChange) },
    ];

    doc.font('Heading').fontSize(13).text('Co urosło (Top 5)');
    doc.moveDown(0.3);
    if (data.growth.length === 0) {
      doc.font('Body').fontSize(10).text('Brak kategorii ze wzrostem w tym tygodniu.');
      doc.moveDown();
    } else {
      drawTable(changeColumns, data.growth, { colorPctColumn: 'PctChange' });
    }

    doc.font('Heading').fontSize(13).text('Co spadło (Top 5)');
    doc.moveDown(0.3);
    if (data.decline.length === 0) {
      doc.font('Body').fontSize(10).text('Brak kategorii ze spadkiem w tym tygodniu.');
      doc.moveDown();
    } else {
      drawTable(changeColumns, data.decline, { colorPctColumn: 'PctChange' });
    }

    doc.font('Heading').fontSize(13).text('Kanały — porównanie');
    doc.moveDown(0.3);
    drawTable(
      [
        { key: 'Channel', header: 'Kanał', width: pageWidth * 0.25, value: (r) => r.Channel },
        { key: 'NetAmount', header: 'Sprzedaż netto', width: pageWidth * 0.3, align: 'right', value: (r) => pln(r.NetAmount) },
        { key: 'WowPct', header: 'WoW', width: pageWidth * 0.2, align: 'right', value: (r) => pct(r.WowPct) },
        { key: 'YoyPct', header: 'YoY', width: pageWidth * 0.2, align: 'right', value: (r) => pct(r.YoyPct) },
      ],
      data.channels,
      { colorPctColumn: null }
    );

    doc.font('Heading').fontSize(13).fillColor('black').text('Insights & Decyzje');
    doc.moveDown(0.3);
    if (insights.length === 0) {
      doc.font('Body').fontSize(9).fillColor('gray').text(
        'Brak przekazanych insightów — uzupełnij ręcznie na podstawie liczb powyżej ' +
        '(sezonowość, promocje, dostępność towaru) — patrz SKILL.md, krok 4.',
        { italic: true }
      );
      doc.fillColor('black').moveDown(0.5);
      doc.font('Body').fontSize(11).text('• ______________________________________________');
      doc.text('• ______________________________________________');
      doc.text('• ______________________________________________');
    } else {
      doc.font('Body').fontSize(11);
      insights.forEach((insight) => doc.text(`• ${insight}`));
    }

    doc.end();
  });
}

const EXCEL_HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2F5496' } };
const EXCEL_HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' } };
const EXCEL_ALT_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } };
const EXCEL_POSITIVE_FONT = { color: { argb: 'FF1E7B34' } };
const EXCEL_NEGATIVE_FONT = { color: { argb: 'FFB00020' } };
const THIN_BORDER = { style: 'thin', color: { argb: 'FFCCCCCC' } };

function styleHeaderRow(row) {
  row.eachCell((cell) => {
    cell.fill = EXCEL_HEADER_FILL;
    cell.font = EXCEL_HEADER_FONT;
    cell.alignment = { vertical: 'middle' };
    cell.border = { top: THIN_BORDER, bottom: THIN_BORDER, left: THIN_BORDER, right: THIN_BORDER };
  });
}

function styleDataRow(row, idx) {
  row.eachCell((cell) => {
    if (idx % 2 === 1) cell.fill = EXCEL_ALT_FILL;
    cell.border = { top: THIN_BORDER, bottom: THIN_BORDER, left: THIN_BORDER, right: THIN_BORDER };
  });
}

function stylePctCell(cell, value) {
  if (value === null || value === undefined) return;
  cell.font = Number(value) >= 0 ? EXCEL_POSITIVE_FONT : EXCEL_NEGATIVE_FONT;
  cell.numFmt = '+0.0"%";-0.0"%"';
}

async function buildExcel(data, outPath, insights) {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'poniedzialkowy-raport-handlowy';
  wb.created = new Date();

  const wow = data.changes.find((c) => c.Label === 'WoW');
  const yoy = data.changes.find((c) => c.Label === 'YoY');

  const summarySheet = wb.addWorksheet('Podsumowanie');
  summarySheet.columns = [{ width: 28 }, { width: 20 }];
  const summaryRows = [
    ['Tydzień', data.meta.CurrentWeek],
    ['Okres', `${fmtDate(data.meta.WeekStart)} – ${fmtDate(data.meta.WeekEnd)}`],
    ['Sprzedaż netto (PLN)', Number(data.summary.NetAmount ?? 0)],
    ['Transakcje', data.summary.Transactions ?? 0],
    ['Średni koszyk (PLN)', Number(data.summary.AvgBasket ?? 0)],
    ['Zmiana WoW (%)', wow ? Number(wow.PctChange) : null],
    ['Zmiana YoY (%)', yoy ? Number(yoy.PctChange) : null],
  ];
  summaryRows.forEach(([label, value]) => {
    const row = summarySheet.addRow([label, value]);
    row.getCell(1).font = { bold: true };
    row.getCell(1).border = { top: THIN_BORDER, bottom: THIN_BORDER, left: THIN_BORDER, right: THIN_BORDER };
    row.getCell(2).border = { top: THIN_BORDER, bottom: THIN_BORDER, left: THIN_BORDER, right: THIN_BORDER };
    if (label.includes('%')) stylePctCell(row.getCell(2), value);
  });

  function addChangeSheet(name, rows) {
    const sheet = wb.addWorksheet(name);
    sheet.columns = [
      { header: 'Kategoria', key: 'Category', width: 20 },
      { header: 'Kanał', key: 'Channel', width: 12 },
      { header: 'Zmiana (%)', key: 'PctChange', width: 14 },
    ];
    styleHeaderRow(sheet.getRow(1));
    rows.forEach((r, idx) => {
      const row = sheet.addRow({ Category: r.Category, Channel: r.Channel, PctChange: Number(r.PctChange) });
      styleDataRow(row, idx);
      stylePctCell(row.getCell('PctChange'), r.PctChange);
    });
  }

  addChangeSheet('Co urosło', data.growth);
  addChangeSheet('Co spadło', data.decline);

  const channelSheet = wb.addWorksheet('Kanały');
  channelSheet.columns = [
    { header: 'Kanał', key: 'Channel', width: 14 },
    { header: 'Sprzedaż netto (PLN)', key: 'NetAmount', width: 20 },
    { header: 'WoW (%)', key: 'WowPct', width: 12 },
    { header: 'YoY (%)', key: 'YoyPct', width: 12 },
  ];
  styleHeaderRow(channelSheet.getRow(1));
  data.channels.forEach((r, idx) => {
    const row = channelSheet.addRow({
      Channel: r.Channel,
      NetAmount: Number(r.NetAmount),
      WowPct: r.WowPct !== null ? Number(r.WowPct) : null,
      YoyPct: r.YoyPct !== null ? Number(r.YoyPct) : null,
    });
    styleDataRow(row, idx);
    stylePctCell(row.getCell('WowPct'), r.WowPct);
    stylePctCell(row.getCell('YoyPct'), r.YoyPct);
  });

  const insightsSheet = wb.addWorksheet('Insights');
  insightsSheet.columns = [{ width: 90 }];
  if (insights.length === 0) {
    insightsSheet.addRow(['Brak przekazanych insightów — patrz SKILL.md, krok 4.']).font = { italic: true, color: { argb: 'FF808080' } };
  } else {
    insights.forEach((insight) => insightsSheet.addRow([`• ${insight}`]));
  }

  await wb.xlsx.writeFile(outPath);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  ensureDependencies();
  fs.mkdirSync(args.out, { recursive: true });

  const data = await fetchData();
  const insights = loadInsights(args.insightsFile);

  if (args.pdf) {
    const fonts = resolveFonts();
    const pdfPath = path.join(args.out, `raport-${data.meta.CurrentWeek}.pdf`);
    await buildPdf(data, pdfPath, fonts, insights);
    console.log(`PDF:   ${pdfPath}`);
  }

  if (args.xlsx) {
    const xlsxPath = path.join(args.out, `raport-${data.meta.CurrentWeek}-tabele.xlsx`);
    await buildExcel(data, xlsxPath, insights);
    console.log(`Excel: ${xlsxPath}`);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
