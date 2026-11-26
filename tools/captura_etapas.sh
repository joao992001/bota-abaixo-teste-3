#!/bin/bash
# Navega pelo jogo com TECLADO DE VERDADE (xdotool + Xvfb) e tira capturas de cada etapa (menu → mapas → 5 etapas).
# Pega erros que os testes sem tela não pegam (o .exe fechava ao escolher o mapa). Requer xdotool (apt-get install -y xdotool).
export DISPLAY=:95
Xvfb :95 -screen 0 1920x1080x24 >/dev/null 2>&1 &
XP=$!
sleep 2
godot --path "$(dirname "$0")/../game" --resolution 1920x1080 > /tmp/flow5.log 2>&1 &
GP=$!
sleep 14
WID=$(xdotool search --pid $GP | tail -1)
xdotool windowmap $WID 2>/dev/null; xdotool windowfocus --sync $WID 2>/dev/null; xdotool mousemove 1900 1070
k() { xdotool keydown "$1"; sleep 0.12; xdotool keyup "$1"; sleep "${2:-1.0}"; }
shot() { ffmpeg -v quiet -y -f x11grab -video_size 1920x1080 -i :95 -frames:v 1 "/tmp/f5_$1.png"; }
k space; k space; k Right; k space 2
shot 1_engenhocas
k Return; shot 2_eventos
k Return; shot 3_vidas
k Return; k space; k r; shot 4_jogadores
k Return 1.5; shot 5_detonar
echo "vivo? $(kill -0 $GP 2>/dev/null && echo sim || echo NAO)"
kill $GP; kill $XP
