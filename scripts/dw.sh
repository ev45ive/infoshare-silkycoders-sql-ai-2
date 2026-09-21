#!/usr/bin/env bash
#
# RetailDW workshop helper.
#
#   ./scripts/dw.sh up        start the SQL Server container
#   ./scripts/dw.sh build     build the database project (produces the dacpac)
#   ./scripts/dw.sh publish   publish the dacpac to the local container
#   ./scripts/dw.sh seed [batch] [target]  truncate + load staging data (target: sales default, items, customers); batch applies to sales/customers
#   ./scripts/dw.sh etl [target]  run the load procedure for the given target (sales default, items, customers)
#   ./scripts/dw.sh smoke     run the smoke test
#   ./scripts/dw.sh regression <ticket-id>  load data/<ticket-id>-seed.sql, run tests/<ticket-id>-regression.sql
#   ./scripts/dw.sh reset     drop and rebuild the database from scratch
#   ./scripts/dw.sh diff      generate a deploy diff script from the dacpac vs the target database
#   ./scripts/dw.sh sql "..." run an ad-hoc query
#   ./scripts/dw.sh baseline  up + build + publish + seed + etl + smoke
#   ./scripts/dw.sh wsl-memory [GB]  ensure WSL2 has enough memory for SQL Server (default 3GB)
#
set -euo pipefail
set +H 2>/dev/null || true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="127.0.0.1,14330"
DB="RetailDW"
WSL_MIN_MEMORY_GB=3
SA_USER="sa"
SA_PASS="${MSSQL_SA_PASSWORD:-Workshop_Dev2026#}"

export PATH="$PATH:$HOME/.dotnet/tools"

winpath() { # winpath <path> - sqlcmd/sqlpackage are Windows binaries
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

q() { # q <database> <query>
  sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -b -d "$1" -Q "$2"
}

f() { # f <database> <file>
  sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -b -d "$1" -i "$(winpath "$2")"
}

cmd_wsl_memory() { # cmd_wsl_memory [GB] - ensure .wslconfig grants WSL2 enough RAM for sqlservr (>=2000MB required)
  local target_gb="${1:-$WSL_MIN_MEMORY_GB}"
  local target="${target_gb}GB"
  local winhome="${USERPROFILE:-}"
  if [ -z "$winhome" ]; then
    echo "USERPROFILE is not set - cannot locate .wslconfig" >&2
    return 1
  fi

  local cfg
  if command -v cygpath >/dev/null 2>&1; then
    cfg="$(cygpath -u "$winhome")/.wslconfig"
  else
    cfg="$winhome/.wslconfig"
  fi

  if [ -f "$cfg" ] && grep -Eq "^[[:space:]]*memory[[:space:]]*=[[:space:]]*${target}[[:space:]]*\$" "$cfg"; then
    echo "WSL2 memory already set to $target in $cfg - no change"
    return 0
  fi

  touch "$cfg"
  if ! grep -q '^\[wsl2\]' "$cfg"; then
    printf '[wsl2]\n%s\n' "$(cat "$cfg")" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  fi
  if grep -Eq '^[[:space:]]*memory[[:space:]]*=' "$cfg"; then
    sed -i -E "s/^[[:space:]]*memory[[:space:]]*=.*/memory=${target}/" "$cfg"
  else
    awk -v line="memory=${target}" '{ print } /^\[wsl2\]/ && !done { print line; done=1 }' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  fi

  echo "updated $cfg -> memory=${target}"
  echo "restarting WSL to apply new memory limit..."
  wsl.exe --shutdown
  echo "WSL restarted. Start Docker Desktop again before running './scripts/dw.sh up'."
}

cmd_up() {
  if sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -l 3 -Q "SELECT 1" >/dev/null 2>&1; then
    echo "SQL Server is ready on $SERVER"
    return 0
  fi

  docker compose -f "$ROOT/docker-compose.yml" up -d
  echo "waiting for SQL Server..."
  for _ in $(seq 1 30); do
    if sqlcmd -S "$SERVER" -U "$SA_USER" -P "$SA_PASS" -C -l 3 -Q "SELECT 1" >/dev/null 2>&1; then
      echo "SQL Server is ready on $SERVER"
      return 0
    fi
    sleep 3
  done
  echo "SQL Server did not become ready in time" >&2
  return 1
}

cmd_build() {
  dotnet build "$ROOT/RetailDW/RetailDW.sqlproj"
}

cmd_publish() {
  local dacpac
  dacpac="$(winpath "$ROOT/RetailDW/bin/Debug/RetailDW.dacpac")"
  MSYS_NO_PATHCONV=1 sqlpackage \
    /Action:Publish \
    /SourceFile:"$dacpac" \
    /TargetServerName:"$SERVER" \
    /TargetDatabaseName:"$DB" \
    /TargetUser:"$SA_USER" \
    /TargetPassword:"$SA_PASS" \
    /TargetTrustServerCertificate:True
}

cmd_diff() { # cmd_diff [outfile] - dacpac (source) vs target database (target), no changes applied
  local dacpac outfile
  dacpac="$(winpath "$ROOT/RetailDW/bin/Debug/RetailDW.dacpac")"
  outfile="$(winpath "${1:-$ROOT/analyses/diff.sql}")"
  MSYS_NO_PATHCONV=1 sqlpackage \
    /Action:Script \
    /SourceFile:"$dacpac" \
    /TargetServerName:"$SERVER" \
    /TargetDatabaseName:"$DB" \
    /TargetUser:"$SA_USER" \
    /TargetPassword:"$SA_PASS" \
    /TargetTrustServerCertificate:True \
    /OutputPath:"$outfile"
  echo "diff script written to ${1:-$ROOT/analyses/diff.sql}"
}

cmd_seed() { # cmd_seed [batch] [target] - target: sales (default, data/0<batch>-staging-batch-<batch>.sql), items (data/03-staging-salesitems-batch-1.sql) or customers (data/0<3+batch>-staging-customers-batch-<batch>.sql)
  local batch="${1:-1}"
  local target="${2:-sales}"
  case "$target" in
    sales) f "$DB" "$ROOT/data/0${batch}-staging-batch-${batch}.sql" ;;
    items) f "$DB" "$ROOT/data/03-staging-salesitems-batch-1.sql" ;;
    returns) f "$DB" "$ROOT/data/06-staging-returns-batch-1.sql" ;;
    inventory)
      case "$batch" in
        1) f "$DB" "$ROOT/data/07-staging-inventory-batch-1.sql" ;;
        2) f "$DB" "$ROOT/data/08-staging-inventory-batch-2.sql" ;;
        *) echo "unknown inventory batch: $batch (expected 1|2)" >&2; return 1 ;;
      esac
      ;;
    dataquality) f "$DB" "$ROOT/data/09-dataquality-seed.sql" ;;
    customers)
      case "$batch" in
        1) f "$DB" "$ROOT/data/04-staging-customers-batch-1.sql" ;;
        2) f "$DB" "$ROOT/data/05-staging-customers-batch-2.sql" ;;
        *) echo "unknown customers batch: $batch (expected 1|2)" >&2; return 1 ;;
      esac
      ;;
    *) echo "unknown seed target: $target (expected sales|items|returns|inventory|dataquality|customers)" >&2; return 1 ;;
  esac
}

cmd_etl() { # cmd_etl [target] - target: sales (default, etl.LoadFactSales), items (etl.LoadFactSalesItem), returns (etl.LoadReturns), inventory (etl.LoadInventorySnapshot) or customers (etl.LoadCustomers)
  local target="${1:-sales}"
  local proc source
  case "$target" in
    sales)     proc="etl.LoadFactSales";          source="POS" ;;
    items)     proc="etl.LoadFactSalesItem";      source="POS" ;;
    returns)   proc="etl.LoadReturns";            source="POS" ;;
    inventory) proc="etl.LoadInventorySnapshot";  source="WMS" ;;
    customers) proc="etl.LoadCustomers";          source="CRM" ;;
    *) echo "unknown etl target: $target (expected sales|items|returns|inventory|customers)" >&2; return 1 ;;
  esac
  q "$DB" "DECLARE @l INT;
           EXEC $proc @SourceSystem = N'$source', @LoadId = @l OUTPUT;
           SELECT LoadId, PackageName, Status, RowsInserted, RowsUpdated, RowsRejected
           FROM dbo.LoadLog ORDER BY LoadId;"
}

cmd_smoke() { f "$DB" "$ROOT/tests/smoke-test.sql"; }

cmd_regression() { # cmd_regression <ticket-id> - load data/<ticket-id>-seed.sql, run etl, then run tests/<ticket-id>-regression.sql
  local ticket="${1:?usage: dw.sh regression <ticket-id>}"
  local seed="$ROOT/data/${ticket}-seed.sql"
  local test="$ROOT/tests/${ticket}-regression.sql"
  [ -f "$seed" ] || { echo "missing $seed" >&2; return 1; }
  [ -f "$test" ] || { echo "missing $test" >&2; return 1; }
  f "$DB" "$seed"
  cmd_etl
  f "$DB" "$test"
}

cmd_reset() {
  # sa's default database can end up pointing at $DB; repoint it first so a
  # dropped $DB doesn't strand the login with "Cannot open user default database".
  q "master" "ALTER LOGIN [$SA_USER] WITH DEFAULT_DATABASE = master;
              IF DB_ID('$DB') IS NOT NULL
              BEGIN
                  ALTER DATABASE [$DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                  DROP DATABASE [$DB];
              END"
  cmd_build
  cmd_publish
}

cmd_baseline() {
  cmd_up
  cmd_build
  cmd_publish
  cmd_seed
  cmd_etl
  cmd_smoke
}

case "${1:-}" in
  up)       cmd_up ;;
  build)    cmd_build ;;
  publish)  cmd_publish ;;
  seed)     cmd_seed "${2:-}" "${3:-}" ;;
  etl)      cmd_etl "${2:-}" ;;
  smoke)    cmd_smoke ;;
  regression) cmd_regression "${2:-}" ;;
  reset)    cmd_reset ;;
  diff)     cmd_diff "${2:-}" ;;
  baseline) cmd_baseline ;;
  sql)      q "$DB" "${2:?usage: dw.sh sql \"<query>\"}" ;;
  wsl-memory) cmd_wsl_memory "${2:-}" ;;
  *)        sed -n '3,15p' "${BASH_SOURCE[0]}" ; exit 1 ;;
esac
