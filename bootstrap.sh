#!/usr/bin/env bash
#
# bootstrap.sh -- verify that this repository is installed correctly.
#
# This script is READ-ONLY by default. It reads the install mapping straight
# from install.sh (`--print-map`), so the two can never disagree: if you add a
# file to install.sh, this script starts checking it automatically.
#
# What it checks:
#   1. Every mapping in install.sh points at a source file that still exists.
#   2. Every mapped target in $HOME is a symlink to that exact source.
#   3. No stale symlinks in $HOME pointing into this repository that are no
#      longer part of the mapping (these silently change shell behaviour).
#   4. The managed zsh files parse (`zsh -n`).
#   5. Optional: an interactive zsh starts without errors (--warm, on by default).
#
# Exit status: 0 = everything verified, 1 = at least one problem found.
#
# Usage: ./bootstrap.sh [--fix] [--no-warm] [--prompt starship|p10k|auto]

set -Eeuo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"

PROMPT_FLAVOR="auto"
FIX=0
WARM=1

PROBLEMS=0
CHECKS=0
OKS=0

log() {
  printf '\n==> %s\n' "$1"
}

problem() {
  PROBLEMS=$(( PROBLEMS + 1 ))
  printf '  [PROBLEM] %s\n' "$1"
}

ok() {
  OKS=$(( OKS + 1 ))
  printf '  [ok]      %s\n' "$1"
}

note() {
  printf '  [note]    %s\n' "$1"
}

die() {
  printf '\n==> ERROR: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Verifies that every path managed by install.sh is linked correctly, and that
the install mapping itself is still valid. Read-only unless --fix is given.

Options:
      --prompt FLAVOUR  Which prompt flavour to verify: starship (default),
                        p10k, or auto (detect it from ~/.zshrc)
      --fix             Repair missing/incorrect links by delegating to
                        ./install.sh --link-only (existing files are backed up)
      --no-warm         Skip the interactive zsh smoke test
  -h, --help            Show this help message

Exit status: 0 = verified, 1 = problems found.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt)
        if [[ $# -lt 2 ]]; then
          die "--prompt requires an argument: starship, p10k or auto"
        fi
        case "$2" in
          starship|p10k|auto) PROMPT_FLAVOR="$2" ;;
          *) die "invalid --prompt value: $2 (expected starship, p10k or auto)" ;;
        esac
        shift 2
        ;;
      --fix)
        FIX=1
        shift
        ;;
      --no-warm)
        WARM=0
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1 (try --help)"
        ;;
    esac
  done
}

# Resolve ~/.zshrc to decide which prompt flavour is installed.
detect_prompt_flavor() {
  local target=""

  if [[ -L "$HOME/.zshrc" ]]; then
    target="$(readlink "$HOME/.zshrc" 2>/dev/null || true)"
  fi

  case "$target" in
    */p10k/*) printf 'p10k' ;;
    *)        printf 'starship' ;;
  esac
}

# Verify one mapping entry: $1 = source, $2 = target, $3 = required|optional.
verify_mapping() {
  local src="$1"
  local dest="$2"
  local mode="$3"
  local current

  CHECKS=$(( CHECKS + 1 ))

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    if [[ "$mode" == "optional" ]]; then
      note "optional file not present: ${src#"$REPO_ROOT"/} (skipped by install.sh)"
    else
      problem "install.sh maps a source that does not exist: ${src#"$REPO_ROOT"/}"
    fi
    return 0
  fi

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    problem "not installed: ${dest#"$HOME"/}  (expected -> ${src#"$REPO_ROOT"/})"
    return 0
  fi

  current="$(readlink "$dest" 2>/dev/null || true)"

  if [[ -z "$current" ]]; then
    problem "not a symlink: ${dest#"$HOME"/}  (a real file or directory is in the way)"
    return 0
  fi

  # Normalise a trailing slash so ".../nvim/" matches ".../nvim".
  while [[ "$current" == */ && "$current" != "/" ]]; do
    current="${current%/}"
  done

  if [[ "$current" == "$src" ]]; then
    ok "${dest#"$HOME"/} -> ${src#"$REPO_ROOT"/}"
  else
    problem "wrong target: ${dest#"$HOME"/} -> $current (expected $src)"
  fi

  return 0
}

# Find symlinks that point into this repository but are not in the mapping.
verify_no_stale_links() {
  local map="$1"
  local dirs
  local dir link target found_stale=0

  dirs=("$HOME" "$HOME/.config" "$HOME/.local/bin")

  for dir in "${dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      continue
    fi

    while IFS= read -r -d '' link; do
      target="$(readlink "$link" 2>/dev/null || true)"

      while [[ "$target" == */ && "$target" != "/" ]]; do
        target="${target%/}"
      done

      case "$target" in
        "$REPO_ROOT"/*) ;;
        *) continue ;;
      esac

      # Is this target part of the mapping?
      if ! printf '%s\n' "$map" | cut -f2 | grep -Fxq -- "$link"; then
        problem "stale symlink not managed by install.sh: $link -> $target"
        found_stale=1
      fi
    done < <(find "$dir" -maxdepth 1 -type l -print0)
  done

  if [[ "$found_stale" -eq 0 ]]; then
    ok "no stale symlinks pointing into this repository"
  else
    note "stale links are leftovers from an older layout; remove them yourself"
    note "with e.g.  rm ~/.tmux.conf   (only after checking the target above)"
  fi

  return 0
}

# `zsh -n` on every mapped zsh file, plus the *.zsh modules inside mapped
# directories (for example zsh/zshrc.d, which is linked as a whole directory).
verify_zsh_syntax() {
  local map="$1"
  local src dest file checked=0 failed=0

  if ! command -v zsh >/dev/null 2>&1; then
    note "zsh is not installed; skipping the syntax check"
    return 0
  fi

  while IFS=$'\t' read -r src dest mode; do
    if [[ -d "$src" ]]; then
      for file in "$src"/*.zsh; do
        [[ -f "$file" ]] || continue
        checked=$(( checked + 1 ))
        if ! zsh -n "$file" 2>/dev/null; then
          problem "zsh syntax error in ${file#"$REPO_ROOT"/}"
          failed=$(( failed + 1 ))
        fi
      done
      continue
    fi

    case "$src" in
      *.zsh|*/zshrc|*/zprofile|*/zshenv|*/zlogin|*/zlogout) ;;
      *) continue ;;
    esac

    [[ -f "$src" ]] || continue

    checked=$(( checked + 1 ))
    if ! zsh -n "$src" 2>/dev/null; then
      problem "zsh syntax error in ${src#"$REPO_ROOT"/}"
      failed=$(( failed + 1 ))
    fi
  done <<< "$map"

  if [[ "$failed" -eq 0 ]]; then
    ok "zsh syntax valid in $checked file(s)"
  fi

  return 0
}

# Report-only checks.
report_environment() {
  local login_shell

  login_shell="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}' || true)"

  # dscl prints an error sentence on failure; only accept a real path.
  case "$login_shell" in
    /*) ;;
    *) login_shell="${SHELL:-unknown}" ;;
  esac

  if [[ "$(basename "$login_shell")" == "zsh" ]]; then
    ok "login shell is zsh ($login_shell)"
  else
    note "login shell is $login_shell, not zsh. Fix with: chsh -s \$(command -v zsh)"
  fi

  if command -v zsh >/dev/null 2>&1; then
    note "zsh: $(zsh --version)"
  else
    problem "zsh is not installed, but ~/.zshrc and friends are linked"
  fi

  if [[ -f "$REPO_ROOT/Brewfile" ]]; then
    if command -v brew >/dev/null 2>&1; then
      note "Homebrew: $(command -v brew)"
    else
      note "Homebrew is not installed; the Brewfile packages are not available"
    fi
  fi

  return 0
}

warm_zsh() {
  local output

  if ! command -v zsh >/dev/null 2>&1; then
    return 0
  fi

  log "Starting an interactive zsh once to check that the configuration loads"

  if ! output="$(zsh -i -c 'exit' 2>&1)"; then
    problem "interactive zsh exited with a non-zero status:"
    printf '%s\n' "$output" | sed 's/^/            /'
    return 0
  fi

  if printf '%s' "$output" | grep -qiE 'parse error|syntax error|command not found|no such file'; then
    problem "interactive zsh printed errors:"
    printf '%s\n' "$output" | sed 's/^/            /'
    return 0
  fi

  ok "interactive zsh started cleanly"
  printf '  [tip]     profile startup module by module with:\n'
  printf '              ZSH_STARTUP_PROFILE=1 zsh -i -c exit 2>&1 | grep ^zsh-startup\n'

  return 0
}

# Read the mapping from install.sh and run every check against it.
# Resets the counters, so it can be called again after a repair.
read_and_verify() {
  # The mapping comes from install.sh itself, so this script cannot drift from
  # the installer. Errors during --print-map are fatal: it means install.sh is
  # broken, and silently "verifying" nothing would be worse than failing.
  local map
  if ! map="$("$INSTALL_SH" --print-map --prompt "$PROMPT_FLAVOR" 2>/dev/null)"; then
    die "could not read the install mapping from $INSTALL_SH --print-map"
  fi

  if [[ -z "$map" ]]; then
    die "$INSTALL_SH --print-map produced no mappings"
  fi

  local src dest mode
  while IFS=$'\t' read -r src dest mode; do
    [[ -n "$src" && -n "$dest" ]] || continue
    verify_mapping "$src" "$dest" "${mode:-required}"
  done <<< "$map"

  log "Checking for stale symlinks and configuration syntax"
  verify_no_stale_links "$map"
  verify_zsh_syntax "$map"

  return 0
}

main() {
  parse_args "$@"

  [[ -x "$INSTALL_SH" ]] || die "$INSTALL_SH is missing or not executable"

  if [[ "$PROMPT_FLAVOR" == "auto" ]]; then
    PROMPT_FLAVOR="$(detect_prompt_flavor)"
  fi

  log "Verifying the install mapping"
  printf '  repository     : %s\n' "$REPO_ROOT"
  printf '  home           : %s\n' "$HOME"
  printf '  prompt flavour : %s\n' "$PROMPT_FLAVOR"

  read_and_verify

  log "Environment"
  report_environment

  if [[ "$WARM" -eq 1 ]]; then
    warm_zsh
  fi

  log "Summary"
  printf '  mappings checked : %d\n' "$CHECKS"
  printf '  checks passed    : %d\n' "$OKS"

  if [[ "$PROBLEMS" -eq 0 ]]; then
    printf '  problems         : 0\n'
    printf '\n==> All checks passed.\n'
    return 0
  fi

  printf '  problems         : %d\n' "$PROBLEMS"

  if [[ "$FIX" -eq 0 ]]; then
    printf '\n==> Some checks failed. Re-run with --fix to repair the links,\n' >&2
    printf '    or see README.md ("Verify an install") for manual steps.\n' >&2
    return 1
  fi

  # Repair, then verify again: a successful repair command is not the same as a
  # healthy install. In particular --link-only cannot remove stale symlinks, so
  # anything still broken must be reported with a non-zero status.
  printf '\n==> Repairing the links with: install.sh --link-only --prompt %s\n' "$PROMPT_FLAVOR"
  if ! "$INSTALL_SH" --link-only --prompt "$PROMPT_FLAVOR"; then
    printf '\n==> The repair command reported failures; review its output above.\n' >&2
    return 1
  fi

  log "Re-checking after the repair"
  PROBLEMS=0
  CHECKS=0
  OKS=0
  read_and_verify

  printf '\n  problems after repair : %d\n' "$PROBLEMS"

  if [[ "$PROBLEMS" -eq 0 ]]; then
    printf '\n==> Repair successful; the install now verifies.\n'
    return 0
  fi

  printf '\n==> %d problem(s) remain after the repair.\n' "$PROBLEMS" >&2
  printf '    Links can be repaired automatically, but stale symlinks (listed\n' >&2
  printf '    above) have to be removed by hand -- they are not part of the\n' >&2
  printf '    current mapping, so nothing knows what should replace them.\n' >&2
  return 1
}

main "$@"
