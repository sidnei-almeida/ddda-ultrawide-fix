#!/usr/bin/env bash
# Dragon's Dogma: Dark Arisen ultrawide fix (21:9 / 32:9) installer for Linux.
# Drops DDDAFix (Lyall) + Ultimate ASI Loader next to DDDA.exe and, on Steam,
# adds the WINEDLLOVERRIDES entry Proton needs to load it.
# https://github.com/sidnei-almeida/ddda-ultrawide-fix
set -euo pipefail

EXE="DDDA.exe"
APPID="367500"
REPO="sidnei-almeida/ddda-ultrawide-fix"
DLL="winmm"                      # the ASI loader is injected as winmm.dll
DLL_OVERRIDE="WINEDLLOVERRIDES=\"$DLL=n,b\""

DRY_RUN=0
UNINSTALL=0
NO_LAUNCH_OPTIONS=0
RESET_INI=0
declare -a PATHS=()

usage() {
  cat <<USAGE
Usage: $0 [--path <game dir>]... [--uninstall] [--dry-run] [--no-launch-options] [--reset-ini]

  --path DIR            Game folder containing $EXE (can be given more than once).
                        Without it, Steam libraries and common launcher paths are searched.
  --uninstall           Remove the fix and the launch option, restore a backed-up winmm.dll.
  --dry-run             Show what would be done without changing anything.
  --no-launch-options   Do not touch Steam's launch options for the game.
  --reset-ini           Overwrite DDDAFix.ini with the shipped defaults (it is kept otherwise).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) shift; [[ $# -gt 0 ]] || { usage; exit 2; }; PATHS+=("$1") ;;
    --uninstall) UNINSTALL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --no-launch-options) NO_LAUNCH_OPTIONS=1 ;;
    --reset-ini) RESET_INI=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

log()  { printf '  %s\n' "$*"; }
ok()   { printf '\033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
err()  { printf '\033[31m✘\033[0m %s\n' "$*" >&2; }

for tool in python3 sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { err "$tool is required."; exit 1; }
done

# --- payload (works from a clone or from `curl | bash`) --------------------

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
PAYLOAD=""
TMP=""
if [[ -n "$HERE" && -f "$HERE/payload/DDDAFix.asi" ]]; then
  PAYLOAD="$HERE/payload"
elif [[ $UNINSTALL -eq 0 ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  log "Downloading payload from GitHub ($REPO)…"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
  PAYLOAD="$(find "$TMP" -maxdepth 2 -type d -name payload | head -1)"
  [[ -n "$PAYLOAD" && -f "$PAYLOAD/DDDAFix.asi" ]] || { err "Download failed."; exit 1; }
fi

if [[ -n "$PAYLOAD" ]]; then
  (cd "$PAYLOAD" && sha256sum --quiet -c SHA256SUMS) || { err "Payload checksum mismatch, refusing to install."; exit 1; }
fi

# --- locate the game -------------------------------------------------------

steam_roots() {
  local r
  for r in \
    "$HOME/.local/share/Steam" \
    "$HOME/.steam/root" \
    "$HOME/.steam/steam" \
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" \
    "$HOME/snap/steam/common/.local/share/Steam"; do
    [[ -d "$r/steamapps" ]] && readlink -f "$r"
  done | sort -u
}

steam_libraries() {
  local root vdf
  for root in $(steam_roots); do
    echo "$root"
    vdf="$root/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || continue
    sed -nE 's/^[[:space:]]*"path"[[:space:]]+"([^"]+)".*$/\1/p' "$vdf" | sed 's#\\\\#/#g'
  done | sort -u
}

find_game() {
  local lib acf dir d
  for lib in $(steam_libraries); do
    acf="$lib/steamapps/appmanifest_$APPID.acf"
    dir="DDDA"
    [[ -f "$acf" ]] && dir="$(sed -nE 's/^[[:space:]]*"installdir"[[:space:]]+"([^"]+)".*$/\1/p' "$acf" | head -1)"
    d="$lib/steamapps/common/${dir:-DDDA}"
    [[ -f "$d/$EXE" ]] && echo "$d"
  done
  # Heroic / Lutris / Bottles / manual installs: shallow search in common roots
  local root
  for root in "$HOME/Games" "$HOME/.local/share/lutris" "$HOME/.var/app/com.heroicgameslauncher.hgl" \
              "$HOME/.var/app/net.lutris.Lutris" "$HOME/.local/share/bottles" "$HOME/.var/app/com.usebottles.bottles"; do
    [[ -d "$root" ]] || continue
    find -L "$root" -maxdepth 6 -type f -name "$EXE" -printf '%h\n' 2>/dev/null || true
  done
}

canon() { while IFS= read -r p; do readlink -f -- "$p"; done; }

if [[ ${#PATHS[@]} -eq 0 ]]; then
  mapfile -t PATHS < <(find_game | canon | sort -u)
fi

if [[ ${#PATHS[@]} -eq 0 ]]; then
  err "Could not find $EXE. Pass the game folder explicitly:"
  log "$0 --path \"/path/to/steamapps/common/DDDA\""
  exit 1
fi

# --- install / remove ------------------------------------------------------

FILES=(winmm.dll DDDAFix.asi)

apply_fix() {
  local dir="$1" f
  if pgrep -x "$EXE" >/dev/null 2>&1; then
    err "The game is running. Close it and run the installer again."
    return 1
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] would copy winmm.dll, DDDAFix.asi and DDDAFix.ini into $dir"
    return
  fi
  if [[ -f "$dir/winmm.dll" ]] && ! cmp -s "$dir/winmm.dll" "$PAYLOAD/winmm.dll"; then
    cp -p "$dir/winmm.dll" "$dir/winmm.dll.bak"
    warn "Existing winmm.dll backed up as winmm.dll.bak"
  fi
  for f in "${FILES[@]}"; do
    cp "$PAYLOAD/$f" "$dir/$f.tmp" && mv -f "$dir/$f.tmp" "$dir/$f"
  done
  if [[ -f "$dir/DDDAFix.ini" && $RESET_INI -eq 0 ]]; then
    log "DDDAFix.ini already present, keeping your settings (use --reset-ini to overwrite)"
  else
    cp "$PAYLOAD/DDDAFix.ini" "$dir/DDDAFix.ini"
  fi
  ok "Installed into $dir"
}

remove_fix() {
  local dir="$1" f
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] would remove winmm.dll, DDDAFix.asi, DDDAFix.ini and DDDAFix.log from $dir"
    return
  fi
  for f in "${FILES[@]}" DDDAFix.ini DDDAFix.log; do rm -f "$dir/$f"; done
  if [[ -f "$dir/winmm.dll.bak" ]]; then
    mv "$dir/winmm.dll.bak" "$dir/winmm.dll"
    ok "Restored previous winmm.dll"
  fi
  ok "Removed from $dir"
}

# --- Steam launch options (Linux/Proton needs the DLL override) -------------

localconfigs() {
  local root
  for root in $(steam_roots); do
    find "$root/userdata" -mindepth 3 -maxdepth 3 -name localconfig.vdf 2>/dev/null
  done
}

# Prints the launch options the game should end up with, merging our DLL into
# an existing WINEDLLOVERRIDES list (ReShade's d3d9, dinput8 mods, gamescope
# and anything else already there are preserved). Exit codes:
#   0 changed (new value on stdout)   3 app not found   4 already correct
compute_launch_options() {
  python3 - "$1" "$APPID" "$DLL" "$UNINSTALL" <<'PY'
import re, sys
path, appid, dll, uninstall = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
s = open(path, encoding="utf-8", errors="surrogateescape").read()
m = None
for cand in re.finditer(r'"%s"\s*\{' % appid, s):
    depth, i = 0, cand.end() - 1
    while i < len(s):
        if s[i] == "{": depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0: break
        i += 1
    block = s[cand.start():i + 1]
    if "LaunchOptions" in block or "LastPlayed" in block or "Playtime" in block:
        m = block; break
if m is None:
    sys.exit(3)
lo = re.search(r'"LaunchOptions"\s*"((?:[^"\\]|\\.)*)"', m)
current = lo.group(1).replace('\\"', '"') if lo else ""

def merge(opts):
    ov = re.search(r'WINEDLLOVERRIDES="([^"]*)"', opts)
    if not ov:
        return ('WINEDLLOVERRIDES="%s=n,b" ' % dll) + (opts if "%command%" in opts else (opts + " %command%").strip())
    val = ov.group(1)
    if re.search(r'(^|[,;])%s(=|$|[,;])' % re.escape(dll), val):
        return opts
    g = re.match(r'^([A-Za-z0-9_.-]+(?:,[A-Za-z0-9_.-]+)*)=n,b$', val)
    newval = (g.group(1) + "," + dll + "=n,b") if g else (val + ";" + dll + "=n,b")
    return opts[:ov.start(1)] + newval + opts[ov.end(1):]

def strip(opts):
    ov = re.search(r'WINEDLLOVERRIDES="([^"]*)"', opts)
    if not ov:
        return opts
    val = ov.group(1)
    g = re.match(r'^([A-Za-z0-9_.-]+(?:,[A-Za-z0-9_.-]+)*)=n,b$', val)
    if g:
        names = [n for n in g.group(1).split(",") if n != dll]
        newval = (",".join(names) + "=n,b") if names else ""
    else:
        parts = [p for p in val.split(";") if not re.match(r'^%s(=|$)' % re.escape(dll), p)]
        newval = ";".join(parts)
    if newval:
        return opts[:ov.start(1)] + newval + opts[ov.end(1):]
    return re.sub(r'\s*WINEDLLOVERRIDES=""\s*', ' ', opts[:ov.start(1)] + opts[ov.end(1):]).strip()

new = strip(current) if uninstall else merge(current)
new = re.sub(r'\s+', ' ', new).strip()
if new == "%command%":
    new = ""
if new == current.strip():
    sys.exit(4)
print(new)
PY
}

write_launch_options() {
  local vdf="$1" new="$2"
  python3 - "$vdf" "$APPID" "$new" <<'PY'
import re, shutil, sys
path, appid, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path, encoding="utf-8", errors="surrogateescape").read()
for cand in re.finditer(r'"%s"\s*\{' % appid, s):
    depth, i = 0, cand.end() - 1
    while i < len(s):
        if s[i] == "{": depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0: break
        i += 1
    block = s[cand.start():i + 1]
    if "LaunchOptions" in block or "LastPlayed" in block or "Playtime" in block:
        start, end = cand.start(), i + 1; break
else:
    sys.exit(3)
esc = new.replace('"', '\\"')
lo = re.search(r'"LaunchOptions"\s*"((?:[^"\\]|\\.)*)"', block)
if lo:
    nb = block[:lo.start()] + '"LaunchOptions"\t\t"%s"' % esc + block[lo.end():]
else:
    ind = re.search(r'\n([ \t]*)"', block)
    indent = ind.group(1) if ind else "\t"
    nb = block[:-1].rstrip() + '\n%s"LaunchOptions"\t\t"%s"\n%s}' % (indent, esc, indent[:-1])
shutil.copy2(path, path + ".dddauw.bak")
open(path, "w", encoding="utf-8", errors="surrogateescape").write(s[:start] + nb + s[end:])
PY
}

for dir in "${PATHS[@]}"; do
  if [[ ! -f "$dir/$EXE" ]]; then
    err "$EXE not found in: $dir"
    continue
  fi
  echo "Game found: $dir"
  if [[ $UNINSTALL -eq 1 ]]; then remove_fix "$dir"; else apply_fix "$dir"; fi
done

if [[ $NO_LAUNCH_OPTIONS -eq 0 ]]; then
  echo
  mapfile -t CFGS < <(localconfigs)
  STEAM_UP=0; pgrep -x steam >/dev/null 2>&1 && STEAM_UP=1
  if [[ ${#CFGS[@]} -eq 0 ]]; then
    warn "No Steam profile found; set the launch option by hand:"
    log "Steam > Dragon's Dogma: Dark Arisen > Properties > Launch options:"
    log "    $DLL_OVERRIDE %command%"
  fi
  for vdf in "${CFGS[@]}"; do
    log "Steam profile: $vdf"
    set +e
    NEW="$(compute_launch_options "$vdf")"; rc=$?
    set -e
    case $rc in
      4) ok "Launch options already correct" ;;
      3) warn "Game not found in this profile (launch it once from Steam first)." ;;
      0)
        if [[ $DRY_RUN -eq 1 ]]; then
          log "[dry-run] would set launch options to: ${NEW:-<empty>}"
        elif [[ $STEAM_UP -eq 1 ]]; then
          warn "Steam is running, so its config can't be edited safely. Close Steam and run this again, or set it by hand:"
          log "Steam > Dragon's Dogma: Dark Arisen > Properties > Launch options:"
          log "    ${NEW:-<leave empty>}"
        else
          write_launch_options "$vdf" "$NEW"
          ok "Launch options set to: ${NEW:-<empty>}"
        fi ;;
      *) warn "Could not read $vdf" ;;
    esac
  done
fi

if [[ $UNINSTALL -eq 0 && $DRY_RUN -eq 0 ]]; then
  echo
  ok "Done. In the game, set your monitor's native resolution (Windowed mode gives you borderless)."
  log "DDDAFix.log appears in the game folder when the fix loads."
fi
