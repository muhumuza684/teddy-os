#!/usr/bin/env bash
# Teddy OS - repository consistency check.
# Fails (exit 1) when the repo drifts apart: versions, branding, encodings, app registration,
# shell conventions, placeholders. Run locally:  bash tools/check-consistency.sh
# Runs in CI as part of "Teddy OS Quality Checks".
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

FAILS=0
command -v node >/dev/null 2>&1 || { echo "  FAIL  node is required to run this check (it is also required to build Teddy OS)"; exit 1; }
# run a Node snippet read from stdin; extra arguments become process.argv.slice(2)
run_node() { local js rc; js="$(mktemp)"; cat > "$js"; node "$js" "$@"; rc=$?; rm -f "$js"; return $rc; }
bad() { echo "  FAIL  $*"; FAILS=$((FAILS + 1)); }
good() { echo "  ok    $*"; }
section() { echo; echo "== $*"; }

# text files we police (tracked, not binary, not lock files, not the test fixtures)
mapfile -t FILES < <(git ls-files | grep -vE '(\.png|\.ico|\.jpg|\.svg)$|package-lock\.json$|^tests/')

section "1. One version everywhere"
VER=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' desktop/package.json | head -n 1)
[ -n "$VER" ] && good "desktop/package.json = $VER (the single source of truth)" || bad "cannot read desktop/package.json version"
BADGE=$(sed -n 's/.*badge\/Version-\([^-]*\(--[^-]*\)\?\)-.*/\1/p' README.md | head -n 1 | sed 's/--/-/')
[ "$BADGE" = "$VER" ] && good "README badge matches" || bad "README version badge is '$BADGE', package.json is '$VER'"
if grep -nE "TEDDY_VERSION=\"[0-9]|TEDDY_OS_VERSION=\"[0-9]" iso-builder/*.sh >/dev/null; then bad "hard-coded version in iso-builder scripts"; else good "ISO scripts read the version from package.json"; fi
if grep -rnE "(Teddy ?OS|TeddyOS) v?[0-9]+\.[0-9]|Version [0-9]+\.[0-9]" desktop/src desktop/electron desktop/public --include=*.js --include=*.jsx --include=*.html --include=*.json | grep -v "utils/version.js" ; then bad "hard-coded product version in desktop code (use utils/version.js)"; else good "no hard-coded versions in desktop code"; fi

section "2. One brand name"
if grep -nE "Bryt ?Ma Tech Uganda|BRYT MA TECH UGANDA|BrytMa|Brytma" "${FILES[@]}" | grep -v "^tools/check-consistency.sh"; then bad "use 'Bryt Ma Tech UG' (never the long or joined form)"; else good "company name is 'Bryt Ma Tech UG' everywhere"; fi
if grep -nE "YOUR_USERNAME|YOUR_NAME|TODO_REPLACE" "${FILES[@]}" | grep -v "^tools/check-consistency.sh"; then bad "placeholder text left in the repo"; else good "no placeholder URLs or names"; fi

section "3. Clean encodings and line endings"
BOMS=$(for f in "${FILES[@]}"; do [ "$(head -c3 "$f" | od -An -tx1 | tr -d ' \n')" = "efbbbf" ] && echo "$f"; done || true)
[ -z "$BOMS" ] && good "no UTF-8 BOM" || bad "UTF-8 BOM in: $BOMS"
CRS=""
for f in "${FILES[@]}"; do
  case "$f" in *.sh|*.yml|*.js|*.jsx|*.json|*.css|*.md|*.html)
    [ "$(tr -cd '\r' < "$f" | wc -c)" -gt 0 ] && CRS="$CRS $f" ;;
  esac
done
[ -z "$CRS" ] && good "LF line endings" || bad "CRLF line endings in:$CRS"
if run_node "${FILES[@]}" <<'JS'
const fs = require('fs');
const pat = /(\u00c3.|\u00c2.|\u00e2\u20ac|\u00f0\u0178)/;
const bad = [];
for (const f of process.argv.slice(2)) {
  let t; try { t = fs.readFileSync(f, 'utf8'); } catch (e) { continue; }
  t.split('\n').forEach((l, i) => { if (pat.test(l)) bad.push(f + ':' + (i + 1)); });
}
if (bad.length) console.log(bad.slice(0, 10).join('\n'));
process.exit(bad.length ? 1 : 0);
JS
then good "no garbled (double-encoded) characters"; else bad "garbled characters found (see lines above)"; fi

section "4. Shell conventions"
for f in iso-builder/*.sh tools/*.sh; do
  head -n1 "$f" | grep -q '^#!' || bad "$f: first line is not a shebang"
  case "$f" in tools/test-*.sh) continue;; esac   # test harnesses count failures, so they do not use 'set -e'
  grep -qE '^set -[euo]+( -o pipefail|o pipefail)?' "$f" || bad "$f: missing 'set -euo pipefail'"
done
good "shebang + strict mode checked for iso-builder/*.sh and tools/*.sh"
for f in $(git ls-files '*.sh' | grep -v '^tests/'); do
  grep -qF "bash -n $f" .github/workflows/quality.yml || bad "$f is not syntax-checked in quality.yml"
done
good "every tracked shell script is syntax-checked in CI (or reported above)"

section "5. App registration (App.jsx and Modes.jsx must agree)"
if run_node <<'JS'
const fs = require('fs');
const app = fs.readFileSync('desktop/src/App.jsx', 'utf8');
const modes = fs.readFileSync('desktop/src/components/Modes.jsx', 'utf8');
const all = (re, s) => [...s.matchAll(re)];
const meta = new Set(all(/\b([a-z]+): \{ title:/g, app).map(m => m[1]));
const task = new Set(all(/\{ id: '([a-z]+)', icon:/g, app).map(m => m[1]));
const rendered = new Set(all(/id === '([a-z]+)'/g, app).map(m => m[1]));
const body = modes.split('export const MODE_APPS')[1] || '';
const modeApps = {};
for (const m of all(/^\s+(\w+): \[([^\]]*)\],?/gm, body)) modeApps[m[1]] = [...m[2].matchAll(/'([a-z]+)'/g)].map(x => x[1]);
const problems = [];
if (!Object.keys(modeApps).length) problems.push('could not read MODE_APPS from Modes.jsx');
if (!meta.size) problems.push('could not read APP_META from App.jsx');
const used = new Set();
for (const [m, ids] of Object.entries(modeApps)) for (const i of ids) {
  used.add(i);
  for (const [name, pool] of [['APP_META', meta], ['TASKBAR_APPS', task], ['render switch', rendered]])
    if (!pool.has(i)) problems.push("mode '" + m + "' lists '" + i + "' but it is missing from " + name);
}
for (const i of meta) if (!used.has(i)) problems.push("app '" + i + "' is in APP_META but in no mode");
console.log('  modes: ' + Object.entries(modeApps).map(([k, v]) => k + '=' + v.length).join(' ') + ' | apps: ' + meta.size);
problems.forEach(p => console.log('  FAIL  ' + p));
process.exit(problems.length ? 1 : 0);
JS
then good "every mode app is registered, in the taskbar and rendered"; else bad "app registration is inconsistent (see lines above)"; fi

section "6. Repo basics"
grep -qi 'MIT' README.md && [ ! -f LICENSE ] && bad "README claims MIT but LICENSE is missing" || good "LICENSE present"
[ -f docs/TEDDY-V2.2-SYSTEM-FEATURES.md ] && good "feature status doc present" || bad "docs/TEDDY-V2.2-SYSTEM-FEATURES.md missing"

echo
if [ "$FAILS" -eq 0 ]; then echo "CONSISTENCY: all checks passed"; else echo "CONSISTENCY: $FAILS check(s) failed"; exit 1; fi
