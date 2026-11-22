#!/bin/bash
# montar-icone-claude.sh <simbolo.svg> <saida.svg>
# Coloca o simbolo oficial do Claude (estrela coral, viewBox 0 0 100 100) dentro de um
# "squircle" claro no formato dos icones de app do macOS, para o atalho do Claude Code no dock.
set -e
SIMB="${1:?simbolo}"; OUT="${2:?saida}"
# conteudo interno do <svg> do simbolo (os <path>), sem a tag externa
INTERNO=$(tr -d '\n' < "$SIMB" | sed -E 's/^.*<svg[^>]*>//; s#</svg>.*$##')
COR=$(tr -d '\n' < "$SIMB" | sed -nE 's/.*<svg[^>]*fill="([^"]+)".*/\1/p'); COR=${COR:-#D97757}
cat > "$OUT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="fundo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#fbf8f2"/>
      <stop offset="1" stop-color="#ece5d8"/>
    </linearGradient>
    <filter id="sombra" x="-20%" y="-20%" width="140%" height="150%">
      <feDropShadow dx="0" dy="4" stdDeviation="5" flood-color="#000" flood-opacity="0.28"/>
    </filter>
  </defs>
  <rect x="18" y="14" width="220" height="220" rx="50" fill="url(#fundo)" filter="url(#sombra)"/>
  <rect x="18.5" y="14.5" width="219" height="219" rx="49.5" fill="none" stroke="#000" stroke-opacity="0.06"/>
  <g transform="translate(58 54) scale(1.40)" fill="$COR">$INTERNO</g>
</svg>
EOF
echo "icone montado: $OUT (cor $COR)"
