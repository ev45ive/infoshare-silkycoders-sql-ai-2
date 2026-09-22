#!/usr/bin/env node
/*
 * Generuje poniedziałkowy przegląd handlowy jako PDF (wg szablonu z
 * ../assets/szablon-raportu.md) oraz proste zestawienie tabel w Excelu.
 *
 * Dane pobierane z reporting.vw_SalesWeekly przez ./query-data.sql
 * (6 recordsetów, ta sama logika wyboru tygodnia co w generate-report.sql).
 *
 * Wymaga: npm install (w tym samym folderze) przed pierwszym uruchomieniem.
 * Konfiguracja połączenia — zmienne środowiskowe (domyślne jak w scripts/dw.sh):
 *   MSSQL_HOST      (domyślnie 127.0.0.1)
 *   MSSQL_PORT      (domyślnie 14330)
 *   MSSQL_DATABASE  (domyślnie RetailDW)
 *   MSSQL_SA_PASSWORD (domyślnie hasło deweloperskie z dw.sh)
 *   FONT_REGULAR / FONT_BOLD — ścieżki do TTF, jeśli domyślne (Arial) nie istnieją
 *
 * Użycie:
 *   node generate-report.js [--out <folder>]
 */

const fs = require('fs');
const path = require('path');
const sql = require('mssql');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');

const SCRIPT_DIR = __dirname;
const QUERY_FILE = path.join(SCRIPT_DIR, 'query-data.sql');

function parseArgs(argv) {
  const args = { out: path.join(SCRIPT_DIR, 'out') };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--out' && argv[i + 1]) {
      args.out = path.resolve(argv[i + 1]);
      i++;
    }
  }
  return args;
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

function buildPdf(data, outPath, fonts) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const stream = fs.createWriteStream(outPath);
    doc.pipe(stream);
    stream.on('finish', resolve);
    stream.on('error', reject);

    doc.registerFont('Body', fonts.regular);
    doc.registerFont('Heading', fonts.bold);

    const wow = data.changes.find((c) => c.Label === 'WoW');
    const yoy = data.changes.find((c) => c.Label === 'YoY');

    doc.font('Heading').fontSize(18).text(`Przegląd handlowy — tydzień ${data.meta.CurrentWeek}`);
    doc.font('Body').fontSize(10)
      .text(`Okres: ${fmtDate(data.meta.WeekStart)} – ${fmtDate(data.meta.WeekEnd)}`)
      .text(`Data raportu: ${new Date().toLocaleString('pl-PL')}`);
    doc.moveDown();

    doc.font('Heading').fontSize(13).text('Podsumowanie wykonania');
    doc.font('Body').fontSize(11).text(
      `Sprzedaż netto ubiegłego tygodnia wyniosła ${pln(data.summary.NetAmount)}, ` +
      `co stanowi ${pct(wow && wow.PctChange)} zmianę tygodniowo i ${pct(yoy && yoy.PctChange)} rok do roku. ` +
      `Liczba transakcji: ${data.summary.Transactions ?? 'b/d'}. Średni koszyk: ${pln(data.summary.AvgBasket)}.`,
      { align: 'justify' }
    );
    doc.moveDown();

    function drawTable(title, rows, valueLabel) {
      doc.font('Heading').fontSize(13).text(title);
      doc.moveDown(0.3);
      if (rows.length === 0) {
        doc.font('Body').fontSize(10).text('Brak pozycji spełniających kryterium w tym tygodniu.');
      } else {
        rows.forEach((row) => {
          doc.font('Body').fontSize(10).text(
            `${row.Category} (${row.Channel})    ${pct(row.PctChange)}`
          );
        });
      }
      doc.moveDown();
    }

    drawTable('Co urosło (Top 5)', data.growth);
    drawTable('Co spadło (Top 5)', data.decline);

    doc.font('Heading').fontSize(13).text('Kanały — porównanie');
    doc.moveDown(0.3);
    data.channels.forEach((row) => {
      doc.font('Body').fontSize(10).text(
        `${row.Channel}: ${pln(row.NetAmount)}   WoW ${pct(row.WowPct)}   YoY ${pct(row.YoyPct)}`
      );
    });
    doc.moveDown();

    doc.font('Heading').fontSize(13).text('Insights & Decyzje');
    doc.font('Body').fontSize(9).fillColor('gray').text(
      'Sekcja wymaga uzupełnienia przez analityka na podstawie liczb powyżej ' +
      '(sezonowość, promocje, dostępność towaru) — patrz SKILL.md, krok 4.',
      { italic: true }
    );
    doc.fillColor('black').moveDown(0.5);
    doc.font('Body').fontSize(11).text('• ______________________________________________');
    doc.text('• ______________________________________________');
    doc.text('• ______________________________________________');

    doc.end();
  });
}

async function buildExcel(data, outPath) {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'poniedzialkowy-raport-handlowy';
  wb.created = new Date();

  const wow = data.changes.find((c) => c.Label === 'WoW');
  const yoy = data.changes.find((c) => c.Label === 'YoY');

  const summarySheet = wb.addWorksheet('Podsumowanie');
  summarySheet.columns = [{ width: 28 }, { width: 20 }];
  summarySheet.addRows([
    ['Tydzień', data.meta.CurrentWeek],
    ['Okres', `${fmtDate(data.meta.WeekStart)} – ${fmtDate(data.meta.WeekEnd)}`],
    ['Sprzedaż netto (PLN)', Number(data.summary.NetAmount ?? 0)],
    ['Transakcje', data.summary.Transactions ?? 0],
    ['Średni koszyk (PLN)', Number(data.summary.AvgBasket ?? 0)],
    ['Zmiana WoW (%)', wow ? Number(wow.PctChange) : null],
    ['Zmiana YoY (%)', yoy ? Number(yoy.PctChange) : null],
  ]);
  summarySheet.getColumn(1).font = { bold: true };

  function addChangeSheet(name, rows) {
    const sheet = wb.addWorksheet(name);
    sheet.columns = [
      { header: 'Kategoria', key: 'Category', width: 20 },
      { header: 'Kanał', key: 'Channel', width: 12 },
      { header: 'Zmiana (%)', key: 'PctChange', width: 14 },
    ];
    sheet.getRow(1).font = { bold: true };
    rows.forEach((r) => sheet.addRow({ Category: r.Category, Channel: r.Channel, PctChange: Number(r.PctChange) }));
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
  channelSheet.getRow(1).font = { bold: true };
  data.channels.forEach((r) =>
    channelSheet.addRow({
      Channel: r.Channel,
      NetAmount: Number(r.NetAmount),
      WowPct: r.WowPct !== null ? Number(r.WowPct) : null,
      YoyPct: r.YoyPct !== null ? Number(r.YoyPct) : null,
    })
  );

  await wb.xlsx.writeFile(outPath);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  fs.mkdirSync(args.out, { recursive: true });

  const fonts = resolveFonts();
  const data = await fetchData();

  const pdfPath = path.join(args.out, `raport-${data.meta.CurrentWeek}.pdf`);
  const xlsxPath = path.join(args.out, `raport-${data.meta.CurrentWeek}-tabele.xlsx`);

  await buildPdf(data, pdfPath, fonts);
  await buildExcel(data, xlsxPath);

  console.log(`PDF:   ${pdfPath}`);
  console.log(`Excel: ${xlsxPath}`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
