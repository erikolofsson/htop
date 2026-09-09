#!/usr/bin/env bash
set -euo pipefail

# Match the macOS dependencies and configure defaults for Homebrew's HEAD build:
# https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/h/htop.rb
# Checked 2026-09-09.

install=false
for arg in "$@"; do
   case "$arg" in
      --install) install=true ;;
      --help|-h)
         echo 'Usage: scripts/build-macos.sh [--install]'
         echo 'Build with Homebrew dependencies; --install runs sudo make install afterward.'
         echo 'Environment: JOBS (CPU count by default), PREFIX (/usr/local by default).'
         exit 0
         ;;
      *)
         printf 'Unknown option: %s\n' "$arg" >&2
         exit 1
         ;;
   esac
done

if (( EUID == 0 )); then
   echo 'Run this script without sudo; --install elevates only make install.' >&2
   exit 1
fi

if [[ $(uname -s) != Darwin ]]; then
   echo 'This script requires macOS.' >&2
   exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
   echo 'Homebrew is required. Install it from https://brew.sh and add brew to PATH.' >&2
   exit 1
fi

if ! xcrun --find clang >/dev/null 2>&1; then
   echo 'Install the Apple command line tools with: xcode-select --install' >&2
   exit 1
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
prefix=${PREFIX:-/usr/local}
if [[ $prefix != /* ]]; then
   echo 'PREFIX must be an absolute path.' >&2
   exit 1
fi
jobs=${JOBS:-$(sysctl -n hw.ncpu)}
if [[ ! $jobs =~ ^[1-9][0-9]*$ ]]; then
   echo 'JOBS must be a positive integer.' >&2
   exit 1
fi

dependencies=(autoconf automake libtool pkgconf ncurses)
missing=()
for dependency in "${dependencies[@]}"; do
   if ! brew list --versions "$dependency" >/dev/null 2>&1; then
      missing+=("$dependency")
   fi
done

if (( ${#missing[@]} )); then
   brew install "${missing[@]}"
fi

for dependency in "${dependencies[@]}"; do
   dependency_prefix=$(brew --prefix "$dependency")
   PATH="$dependency_prefix/bin:$PATH"
done
export PATH

# ncurses is keg-only. Select its headers and library explicitly so configure
# cannot silently fall back to macOS's system ncurses without wheel support.
ncurses_prefix=$(brew --prefix ncurses)
pkgconf_prefix=$(brew --prefix pkgconf)
export PKG_CONFIG="$pkgconf_prefix/bin/pkgconf"
export PKG_CONFIG_PATH="$ncurses_prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export ACLOCAL_PATH="$pkgconf_prefix/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
"$PKG_CONFIG" --atleast-version=6.0 ncursesw
CURSES_CFLAGS=$("$PKG_CONFIG" --cflags ncursesw)
CURSES_LIBS=$("$PKG_CONFIG" --libs ncursesw)
export CURSES_CFLAGS CURSES_LIBS

cd -- "$repo_root"
if [[ -f Makefile ]]; then
   make clean
fi
./autogen.sh
./configure --prefix="$prefix"
make -j"$jobs"

printf '\nBuilt %s/htop with Homebrew ncurses.\n' "$repo_root"

if "$install"; then
   sudo make install
fi
