#!/bin/bash
set -e

DEBUG=${DEBUG:-0}
if [ "$DEBUG" -eq 1 ]; then
  set -x
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

PKGS=(git ansible)

OS=$(detect_os)
echo "Detected OS: $OS"

SUDO=$(get_sudo)

case "$OS" in
arch)
  $SUDO pacman -Sy --noconfirm
  install_pkgs "$SUDO pacman -S --needed --noconfirm" "${PKGS[@]}"
  ;;
ubuntu)
  $SUDO apt-get update && $SUDO apt-get upgrade -y
  install_pkgs "$SUDO apt-get install -y" "${PKGS[@]}"
  ;;
debian)
  $SUDO apt-get update && $SUDO apt-get upgrade -y
  install_pkgs "$SUDO apt-get install -y" "${PKGS[@]}"
  ;;
*)
  echo "Unsupported OS: $OS"
  exit 1
  ;;
esac