#!/usr/bin/env sh
set -eu

VERSION="1.0.0"
DEFAULT_RAW_BASE="https://raw.githubusercontent.com/ArkhiMuttaqina/ssh-picker/main"
raw_base="${SSHPICK_RAW_BASE:-$DEFAULT_RAW_BASE}"
bin_dir="${SSHPICK_BIN_DIR:-${HOME}/.local/bin}"
source_file="${SSHPICK_SOURCE_FILE:-}"
update_path=1
install_deps=1

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --bin-dir DIR       Install into DIR (default: ~/.local/bin)
  --source-file FILE  Install from a local sshpick source file
  --no-path-update    Do not add the bin directory to ~/.profile and ~/.bashrc
  --no-install-deps   Do not try to install missing ssh/fzf packages
  -h, --help          Show this help

Environment:
  SSHPICK_RAW_BASE    Raw repository base URL
  SSHPICK_SOURCE_FILE Local source override
  SSHPICK_BIN_DIR     Install directory override
EOF
}

die() {
  printf 'sshpick installer: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir)
      [ "$#" -ge 2 ] || die "$1 needs a directory"
      bin_dir="$2"
      shift 2
      ;;
    --source-file)
      [ "$#" -ge 2 ] || die "$1 needs a file"
      source_file="$2"
      shift 2
      ;;
    --no-path-update)
      update_path=0
      shift
      ;;
    --no-install-deps)
      install_deps=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[ -n "${HOME:-}" ] || die "HOME is not set"
case "$bin_dir" in
  /*) ;;
  *) die "install directory must be absolute: $bin_dir" ;;
esac

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "missing dependency and sudo is unavailable: $*"
  fi
}

install_dependencies() {
  missing=""
  command -v ssh >/dev/null 2>&1 || missing="$missing ssh"
  command -v fzf >/dev/null 2>&1 || missing="$missing fzf"
  [ -n "$missing" ] || return 0
  [ "$install_deps" -eq 1 ] || die "missing dependencies:$missing"

  printf 'Installing missing dependencies:%s\n' "$missing"
  if command -v apt-get >/dev/null 2>&1; then
    run_privileged apt-get update
    run_privileged apt-get install -y openssh-client fzf
  elif command -v dnf >/dev/null 2>&1; then
    run_privileged dnf install -y openssh-clients fzf
  elif command -v yum >/dev/null 2>&1; then
    run_privileged yum install -y openssh-clients fzf
  elif command -v pacman >/dev/null 2>&1; then
    run_privileged pacman -Sy --needed --noconfirm openssh fzf
  elif command -v apk >/dev/null 2>&1; then
    run_privileged apk add openssh-client-default fzf
  elif command -v brew >/dev/null 2>&1; then
    brew install openssh fzf
  else
    die "unsupported package manager; install OpenSSH client and fzf, then rerun"
  fi
}

make_temp_dir() {
  temp_parent="${TMPDIR:-/tmp}"
  case "$temp_parent" in
    /*) ;;
    *) die "TMPDIR must be absolute: $temp_parent" ;;
  esac
  tmp_dir="$(mktemp -d "${temp_parent%/}/sshpick-install.XXXXXX")"
  case "$tmp_dir" in
    "${temp_parent%/}"/sshpick-install.*) ;;
    *) die "unsafe temporary directory: $tmp_dir" ;;
  esac
}

cleanup() {
  if [ -n "${tmp_file:-}" ] && [ -f "$tmp_file" ]; then
    rm -f -- "$tmp_file"
  fi
  if [ -n "${tmp_dir:-}" ] && [ -d "$tmp_dir" ]; then
    rmdir -- "$tmp_dir" 2>/dev/null || true
  fi
}

fetch_source() {
  tmp_file="$tmp_dir/sshpick"
  if [ -n "$source_file" ]; then
    [ -f "$source_file" ] || die "source file not found: $source_file"
    cp -- "$source_file" "$tmp_file"
  elif command -v curl >/dev/null 2>&1; then
    [ "$raw_base" != "$DEFAULT_RAW_BASE" ] || die "set SSHPICK_RAW_BASE to the published repository raw URL"
    curl -fsSL "$raw_base/sshpick" -o "$tmp_file"
  elif command -v wget >/dev/null 2>&1; then
    [ "$raw_base" != "$DEFAULT_RAW_BASE" ] || die "set SSHPICK_RAW_BASE to the published repository raw URL"
    wget -qO "$tmp_file" "$raw_base/sshpick"
  else
    die "curl or wget is required"
  fi

  first_line="$(sed -n '1p' "$tmp_file")"
  [ "$first_line" = '#!/usr/bin/env bash' ] || die "downloaded payload is not sshpick"
  bash -n "$tmp_file"
}

append_path_block() {
  rc_file="$1"
  start='# >>> sshpick installer >>>'
  end='# <<< sshpick installer <<<'
  [ -f "$rc_file" ] || : > "$rc_file"
  if grep -Fq "$start" "$rc_file"; then
    return 0
  fi

  backup="${rc_file}.sshpick.bak"
  cp -p -- "$rc_file" "$backup"
  {
    printf '\n%s\n' "$start"
    if [ "$bin_dir" = "${HOME}/.local/bin" ]; then
      printf '%s\n' 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
    else
      escaped_bin_dir="$(printf '%s' "$bin_dir" | sed 's/[\\\"]/\\\\&/g')"
      printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' "$escaped_bin_dir" "$escaped_bin_dir"
    fi
    if [ "$rc_file" = "$HOME/.bashrc" ]; then
      printf '%s\n' 'alias sshp=sshpick'
    fi
    printf '%s\n' "$end"
  } >> "$rc_file"
  bash -n "$rc_file" || {
    cp -p -- "$backup" "$rc_file"
    die "syntax check failed for $rc_file; restored $backup"
  }
}

install_dependencies
make_temp_dir
trap cleanup EXIT HUP INT TERM
fetch_source

mkdir -p -- "$bin_dir"
if [ -e "$bin_dir/sshpick" ] || [ -L "$bin_dir/sshpick" ]; then
  cp -p -- "$bin_dir/sshpick" "$bin_dir/sshpick.bak"
fi
install -m 755 "$tmp_file" "$bin_dir/sshpick"
if [ -e "$bin_dir/sshp" ] || [ -L "$bin_dir/sshp" ]; then
  if [ ! -L "$bin_dir/sshp" ] || [ "$(readlink "$bin_dir/sshp")" != "sshpick" ]; then
    die "refusing to replace existing $bin_dir/sshp"
  fi
else
  ln -s sshpick "$bin_dir/sshp"
fi

if [ "$update_path" -eq 1 ]; then
  append_path_block "$HOME/.profile"
  append_path_block "$HOME/.bashrc"
fi

"$bin_dir/sshpick" --version
printf 'Installed:\n  %s\n  %s -> sshpick\n' "$bin_dir/sshpick" "$bin_dir/sshp"
printf 'Open a new shell, or run:\n  export PATH="%s:$PATH"\n' "$bin_dir"
printf 'Then use: sshp\n'
