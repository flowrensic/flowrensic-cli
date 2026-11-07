#!/bin/sh
# Installs the Flowrensic CLI: picks the binary of this OS and arch from a
# release of github.com/flowrensic/flowrensic-cli, checks its sha256 against checksums.txt
# and puts it in a folder it can write to.
#
#   curl -fsSL https://github.com/flowrensic/flowrensic-cli/releases/latest/download/install.sh | sh
#
# FLOWRENSIC_VERSION          a release such as 1.2.3 or v1.2.3, the newest when unset
# FLOWRENSIC_INSTALL_DIR      where to put flowrensic, else /usr/local/bin when writable, else $HOME/.local/bin
# FLOWRENSIC_DOWNLOAD_BASE_URL  where the releases are, https://github.com/flowrensic/flowrensic-cli/releases when unset
set -eu

fail() {
  echo "flowrensic install: $*" >&2
  exit 1
}

os="$(uname -s)"
arch="$(uname -m)"
case "$os/$arch" in
  Linux/x86_64 | Linux/amd64) target=linux-amd64 ;;
  Linux/aarch64 | Linux/arm64) target=linux-arm64 ;;
  Darwin/arm64) target=darwin-arm64 ;;
  *) fail "no binary for $os $arch. There are binaries for Linux x86_64, Linux arm64 and macOS arm64." ;;
esac
binary="flowrensic-$target"

base="${FLOWRENSIC_DOWNLOAD_BASE_URL:-https://github.com/flowrensic/flowrensic-cli/releases}"
version="${FLOWRENSIC_VERSION:-}"
if [ -z "$version" ]; then
  url="$base/latest/download"
else
  url="$base/download/v${version#v}"
fi

if command -v curl >/dev/null 2>&1; then
  download() { curl -fsSL -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  download() { wget -q -O "$2" "$1"; }
else
  fail "needs curl or wget"
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
  fail "needs sha256sum or shasum"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

download "$url/$binary" "$tmp/$binary" || fail "could not download $url/$binary"
download "$url/checksums.txt" "$tmp/checksums.txt" || fail "could not download $url/checksums.txt"

expected="$(awk -v name="$binary" '$2 == name || $2 == "*" name { print $1 }' "$tmp/checksums.txt")"
[ -n "$expected" ] || fail "checksums.txt has no line for $binary"
actual="$(sha256 "$tmp/$binary")"
[ "$actual" = "$expected" ] || fail "the checksum of $binary does not match: got $actual, checksums.txt says $expected"

if [ -n "${FLOWRENSIC_INSTALL_DIR:-}" ]; then
  dir="$FLOWRENSIC_INSTALL_DIR"
elif [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  dir=/usr/local/bin
else
  [ -n "${HOME:-}" ] || fail "HOME is not set, so set FLOWRENSIC_INSTALL_DIR"
  dir="$HOME/.local/bin"
fi
mkdir -p "$dir" || fail "could not make $dir"
chmod 755 "$tmp/$binary"
mv "$tmp/$binary" "$dir/flowrensic" || fail "could not write $dir/flowrensic"

echo "Installed the Flowrensic CLI at $dir/flowrensic"
case ":$PATH:" in
  *":$dir:"*) ;;
  *) echo "$dir is not on PATH. Add it with: export PATH=\"$dir:\$PATH\"" ;;
esac
