#!/bin/bash
# Setup Bota-Abaixo: Godot 4.7.1 headless + RTK (idempotente)
set -euo pipefail
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
if ! godot --version 2>/dev/null | grep -q '^4.7.1.stable'; then
  B=https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable
  Z=Godot_v4.7.1-stable_linux.x86_64.zip
  curl -fsSL -o "$T/$Z" "$B/$Z"; curl -fsSL -o "$T/S.txt" "$B/SHA512-SUMS.txt"
  (cd "$T" && grep " $Z\$" S.txt | sha512sum -c -)
  mkdir -p /opt/godot && unzip -oq "$T/$Z" -d /opt/godot
  ln -sf /opt/godot/Godot_v4.7.1-stable_linux.x86_64 /usr/local/bin/godot
fi
if ! command -v rtk >/dev/null; then
  U=https://github.com/rtk-ai/rtk/releases/latest/download
  A=rtk-x86_64-unknown-linux-musl.tar.gz
  curl -fsSL -o "$T/$A" "$U/$A"; curl -fsSL -o "$T/c.txt" "$U/checksums.txt"
  (cd "$T" && grep " $A\$" c.txt | sha256sum -c -)
  tar -xzf "$T/$A" -C "$T" && install -m755 "$T/rtk" /usr/local/bin/rtk
fi
rtk telemetry disable >/dev/null 2>&1 || true
rtk init -g --auto-patch >/dev/null 2>&1 || true
# projeto: registra class_name (obrigatório numa máquina nova antes do --autotest)
if [ -d bota-abaixo-teste-3/game ]; then (cd bota-abaixo-teste-3 && godot --headless --path game --import >/dev/null 2>&1 || true); fi
