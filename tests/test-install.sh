#!/usr/bin/env bash
#
# tests/test-install.sh -- regression tests for install.sh and bootstrap.sh.
#
# Runs entirely inside a temporary directory: a fresh-clone-like copy of the
# repository plus a throwaway $HOME. Your real home directory and your real
# dotfiles are never touched, and no network access is needed (everything runs
# with --link-only / --print-map).
#
# Usage: ./tests/test-install.sh
# Exit status: 0 = all tests passed, 1 = at least one failure.

set -Eeuo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="$(cd -- "$TEST_DIR/.." && pwd)"

PASSED=0
FAILED=0

pass() {
  PASSED=$(( PASSED + 1 ))
  printf '  ok   %s\n' "$1"
}

fail() {
  FAILED=$(( FAILED + 1 ))
  printf '  FAIL %s\n' "$1"
}

section() {
  printf '\n== %s\n' "$1"
}

cleanup() {
  if [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" && "$KEEP" -eq 0 ]]; then
    rm -rf -- "$WORK_DIR"
  fi
}

# A fresh clone has none of the gitignored, machine-local, or vendored content.
fresh_clone() {
  local dest="$1"
  mkdir -p "$dest"
  tar -cf - -C "$SOURCE_REPO" \
    --exclude='./.git' \
    --exclude='./git/gitconfig.local' \
    --exclude='./zsh/zshrc.d/env.local.zsh' \
    --exclude='./tmux/plugins' \
    --exclude='./nvim/pack/github' \
    --exclude='./config/thefuck/__pycache__' \
    --exclude='./defaults' \
    --exclude='.DS_Store' \
    . | tar -xf - -C "$dest"
  chmod +x "$dest/install.sh" "$dest/bootstrap.sh"
}

count_backups() {
  find "$1" -maxdepth 2 -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' '
}

main() {
  # Normalise the temp path (mktemp can emit "//" when TMPDIR ends in "/").
  # Do NOT use `pwd -P`: install.sh resolves its own location with a logical
  # `cd ... && pwd`, which keeps /var rather than /private/var on macOS, and the
  # symlink-target comparisons below must agree with that.
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"
  WORK_DIR="$(cd -- "$WORK_DIR" && pwd)"
  KEEP="${KEEP:-0}"
  trap cleanup EXIT

  local repo="$WORK_DIR/repo"
  local home="$WORK_DIR/home"
  local log="$WORK_DIR/install.log"

  fresh_clone "$repo"
  mkdir -p "$home"

  printf 'dotfiles test run\n  source repo : %s\n  work dir    : %s\n' "$SOURCE_REPO" "$WORK_DIR"

  # -------------------------------------------------------------------------
  section "install.sh --print-map"

  local map
  if map="$("$repo/install.sh" --print-map 2>/dev/null)"; then
    pass "--print-map exits 0"
  else
    fail "--print-map exited non-zero"
  fi

  local map_lines
  map_lines="$(printf '%s\n' "$map" | grep -c . || true)"
  if [[ "$map_lines" -ge 15 ]]; then
    pass "--print-map reports $map_lines mappings"
  else
    fail "--print-map reported only $map_lines mappings"
  fi

  if printf '%s\n' "$map" | awk -F'\t' 'NF != 3 { exit 1 }'; then
    pass "every mapping has three tab-separated fields"
  else
    fail "a mapping line does not have exactly three fields"
  fi

  local missing=0 src dest mode
  while IFS=$'\t' read -r src dest mode; do
    [[ -n "$src" ]] || continue
    [[ "$mode" == "optional" ]] && continue
    if [[ ! -e "$src" ]]; then
      missing=$(( missing + 1 ))
      printf '       missing source: %s\n' "$src"
    fi
  done <<< "$map"
  if [[ "$missing" -eq 0 ]]; then
    pass "every required mapping points at a file that exists"
  else
    fail "$missing required mapping(s) point at a missing source"
  fi

  # -------------------------------------------------------------------------
  section "fresh install into an empty HOME"

  # Pre-existing user content that must be preserved via backup.
  printf 'USER ZSHRC\n' > "$home/.zshrc"
  mkdir -p "$home/.config/nvim"
  printf 'USER NVIM\n' > "$home/.config/nvim/init.lua"

  if HOME="$home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1; then
    pass "install.sh --link-only exits 0"
  else
    fail "install.sh --link-only failed; last lines:"
    tail -15 "$log" | sed 's/^/       /'
  fi

  local bad=0
  # Re-read the map with HOME set to the test home, so the target paths match
  # the run above (the map printed earlier used the real $HOME).
  local home_map
  home_map="$(HOME="$home" "$repo/install.sh" --print-map --prompt starship 2>/dev/null)"
  while IFS=$'\t' read -r src dest mode; do
    [[ -n "$src" && -n "$dest" ]] || continue
    [[ "$mode" == "optional" ]] && continue
    if [[ ! -L "$dest" ]]; then
      bad=$(( bad + 1 ))
      printf '       not a symlink: %s\n' "$dest"
      continue
    fi
    local actual
    actual="$(readlink "$dest")"
    if [[ "$actual" != "$src" ]]; then
      bad=$(( bad + 1 ))
      printf '       wrong target: %s -> %s (expected %s)\n' "$dest" "$actual" "$src"
    fi
  done <<< "$home_map"

  if [[ "$bad" -eq 0 ]]; then
    pass "every required mapping is a symlink to its repository source"
  else
    fail "$bad mapping(s) were not installed correctly"
  fi

  if [[ -L "$home/.local/bin/adminrun" ]]; then
    pass "bin/local/adminrun is linked into ~/.local/bin"
  else
    fail "bin/local/adminrun was not linked"
  fi

  if [[ -x "$home/.local/bin/adminrun" ]]; then
    pass "the linked adminrun is executable"
  else
    fail "the linked adminrun is not executable"
  fi

  if find "$home/.local/bin" -name 'README*' | grep -q .; then
    fail "a README was linked into ~/.local/bin"
  else
    pass "no documentation leaked into ~/.local/bin"
  fi

  if [[ -L "$home/.editorconfig" ]]; then
    pass ".editorconfig is managed"
  else
    fail ".editorconfig is not managed"
  fi

  if [[ -L "$home/.config/tmux" && "$(readlink "$home/.config/tmux")" == "$repo/tmux" ]]; then
    pass "tmux uses the XDG layout (~/.config/tmux)"
  else
    fail "tmux was not linked to ~/.config/tmux"
  fi

  if [[ -e "$home/.tmux.conf" ]]; then
    fail "install.sh created a legacy ~/.tmux.conf"
  else
    pass "no legacy ~/.tmux.conf was created"
  fi

  # -------------------------------------------------------------------------
  section "backup instead of overwrite"

  local zshrc_backup
  zshrc_backup="$(find "$home" -maxdepth 1 -name '.zshrc.bak.*' | head -1 || true)"
  if [[ -n "$zshrc_backup" && -f "$zshrc_backup" ]]; then
    pass "pre-existing ~/.zshrc was backed up"
  else
    fail "pre-existing ~/.zshrc was not backed up"
  fi

  if [[ -n "$zshrc_backup" ]] && grep -q 'USER ZSHRC' "$zshrc_backup"; then
    pass "the backup kept the original content"
  else
    fail "the backup lost the original content"
  fi

  if find "$home/.config" -maxdepth 1 -name 'nvim.bak.*' | grep -q .; then
    pass "pre-existing ~/.config/nvim directory was backed up"
  else
    fail "pre-existing ~/.config/nvim directory was not backed up"
  fi

  # -------------------------------------------------------------------------
  section "idempotency: running install.sh again"

  local backups_before
  backups_before="$(count_backups "$home")"

  if HOME="$home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1; then
    pass "second run exits 0"
  else
    fail "second run failed; last lines:"
    tail -15 "$log" | sed 's/^/       /'
  fi

  local linked
  linked="$(grep -E '^    linked' "$log" | awk '{print $3}' || true)"
  if [[ "$linked" == "0" ]]; then
    pass "second run created no new symlinks"
  else
    fail "second run reported $linked new symlinks (expected 0)"
  fi

  local backups_after
  backups_after="$(count_backups "$home")"
  if [[ "$backups_before" == "$backups_after" ]]; then
    pass "second run created no new backups"
  else
    fail "second run changed the backup count ($backups_before -> $backups_after)"
  fi

  # -------------------------------------------------------------------------
  section "dry run has no side effects"

  local dry_home="$WORK_DIR/dry-home"
  mkdir -p "$dry_home"
  if HOME="$dry_home" "$repo/install.sh" --link-only --prompt starship --dry-run >"$log" 2>&1; then
    pass "dry run exits 0"
  else
    fail "dry run exited non-zero"
  fi

  local leftover
  leftover="$(find "$dry_home" -mindepth 1 -maxdepth 1 -print | paste -sd, - || true)"
  if [[ -z "$leftover" ]]; then
    pass "dry run left HOME completely empty"
  else
    fail "dry run created files in HOME: $leftover"
  fi

  # -------------------------------------------------------------------------
  section "legacy tmux symlinks"

  local legacy_home="$WORK_DIR/legacy-home"
  mkdir -p "$legacy_home"
  ln -s "$repo/tmux/tmux.conf" "$legacy_home/.tmux.conf"
  printf 'FOREIGN\n' > "$legacy_home/.tmux.conf.foreign"
  ln -s "/etc/hosts" "$legacy_home/.tmux.conf.local"

  HOME="$legacy_home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1 || true

  if [[ -L "$legacy_home/.tmux.conf" ]]; then
    fail "a legacy symlink owned by this repo was not removed"
  else
    pass "legacy ~/.tmux.conf pointing into the repo was removed"
  fi

  if [[ -L "$legacy_home/.tmux.conf.local" ]]; then
    pass "a foreign ~/.tmux.conf.local symlink was left alone"
  else
    fail "a foreign ~/.tmux.conf.local symlink was removed"
  fi

  # -------------------------------------------------------------------------
  section "prompt flavour switching"

  HOME="$home" "$repo/install.sh" --link-only --prompt p10k >"$log" 2>&1 || true
  if [[ "$(readlink "$home/.zshrc")" == "$repo/p10k/zshrc" ]]; then
    pass "p10k flavour links p10k/zshrc to ~/.zshrc"
  else
    fail "p10k flavour did not link p10k/zshrc"
  fi

  if [[ -L "$home/.p10k.zsh" ]]; then
    pass "p10k flavour links ~/.p10k.zsh"
  else
    fail "p10k flavour did not link ~/.p10k.zsh"
  fi

  HOME="$home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1 || true
  if [[ "$(readlink "$home/.zshrc")" == "$repo/zsh/zshrc" ]]; then
    pass "starship flavour links zsh/zshrc back to ~/.zshrc"
  else
    fail "switching back to starship did not restore ~/.zshrc"
  fi

  # -------------------------------------------------------------------------
  section "bootstrap.sh verification"

  local boot_log="$WORK_DIR/bootstrap.log"

  if HOME="$home" "$repo/bootstrap.sh" --no-warm >"$boot_log" 2>&1; then
    pass "bootstrap.sh reports a correct install"
  else
    fail "bootstrap.sh reported problems on a correct install:"
    grep -E 'PROBLEM|problems' "$boot_log" | sed 's/^/       /'
  fi

  local empty_home="$WORK_DIR/empty-home"
  mkdir -p "$empty_home"
  if HOME="$empty_home" "$repo/bootstrap.sh" --no-warm >"$boot_log" 2>&1; then
    fail "bootstrap.sh did not detect an empty HOME"
  else
    pass "bootstrap.sh detects an uninstalled HOME (non-zero exit)"
  fi

  if HOME="$empty_home" "$repo/bootstrap.sh" --no-warm --fix >"$boot_log" 2>&1; then
    pass "bootstrap.sh --fix exits 0"
  else
    fail "bootstrap.sh --fix failed:"
    grep -E 'PROBLEM|failed' "$boot_log" | sed 's/^/       /'
  fi

  if HOME="$empty_home" "$repo/bootstrap.sh" --no-warm >"$boot_log" 2>&1; then
    pass "the repaired HOME verifies cleanly"
  else
    fail "the repaired HOME still reports problems:"
    grep -E 'PROBLEM' "$boot_log" | sed 's/^/       /'
  fi

  # -------------------------------------------------------------------------
  section "uninstall removes only links owned by this repository"

  local un_home="$WORK_DIR/uninstall-home"
  mkdir -p "$un_home"
  printf 'UNINSTALL TEST\n' > "$un_home/.zshrc"
  printf 'FOREIGN TMUX\n' > "$un_home/.tmux.conf"
  HOME="$un_home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1 || true

  local links_before
  links_before="$(find "$un_home" -type l | wc -l | tr -d ' ')"
  if [[ "$links_before" -ge 10 ]]; then
    pass "install created $links_before symlinks to uninstall"
  else
    fail "install created only $links_before symlinks before the uninstall test"
  fi

  HOME="$un_home" "$repo/install.sh" --uninstall --dry-run >"$log" 2>&1 || true
  local links_after_dry
  links_after_dry="$(find "$un_home" -type l | wc -l | tr -d ' ')"
  if [[ "$links_after_dry" == "$links_before" ]]; then
    pass "uninstall --dry-run removed nothing"
  else
    fail "uninstall --dry-run removed links ($links_before -> $links_after_dry)"
  fi

  if HOME="$un_home" "$repo/install.sh" --uninstall >"$log" 2>&1; then
    pass "uninstall exits 0"
  else
    fail "uninstall exited non-zero"
  fi

  local links_left
  links_left="$(find "$un_home" -type l | wc -l | tr -d ' ')"
  if [[ "$links_left" -eq 0 ]]; then
    pass "uninstall removed every symlink pointing into the repository"
  else
    fail "uninstall left $links_left symlink(s) behind"
  fi

  if [[ -f "$un_home/.tmux.conf" ]] && grep -q 'FOREIGN TMUX' "$un_home/.tmux.conf"; then
    pass "uninstall left a foreign regular file untouched"
  else
    fail "uninstall destroyed a foreign regular file"
  fi

  if find "$un_home" -maxdepth 1 -name '.zshrc.bak.*' | grep -q .; then
    pass "uninstall kept the backup created during install"
  else
    fail "uninstall removed the backup"
  fi

  # -------------------------------------------------------------------------
  section "renamed/missing source is detected (the original drift bug)"

  rm -f "$repo/editorconfig"

  if HOME="$empty_home" "$repo/install.sh" --link-only --prompt starship >"$log" 2>&1; then
    fail "install.sh did not fail on a mapping whose source is missing"
  else
    pass "install.sh fails when a mapped source no longer exists"
  fi

  if grep -q 'maps a source that does not exist' "$log"; then
    pass "install.sh names the missing mapping"
  else
    fail "install.sh did not explain the missing mapping"
  fi

  if HOME="$empty_home" "$repo/bootstrap.sh" --no-warm >"$boot_log" 2>&1; then
    fail "bootstrap.sh did not report the missing source"
  else
    pass "bootstrap.sh reports the missing source"
  fi

  # -------------------------------------------------------------------------
  printf '\n== Summary\n  passed: %d\n  failed: %d\n' "$PASSED" "$FAILED"

  if [[ "$FAILED" -eq 0 ]]; then
    printf '\n==> All tests passed.\n'
    return 0
  fi

  printf '\n==> %d test(s) failed. Work dir kept at: %s\n' "$FAILED" "$WORK_DIR" >&2
  KEEP=1
  return 1
}

KEEP="${KEEP:-0}"

main "$@"
