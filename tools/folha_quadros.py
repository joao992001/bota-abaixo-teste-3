"""Folha de quadros: junta recortes de vários quadros PNG numa grade (4 por linha) com o número de cada quadro.
Serve para revisar animação (as 5 batidas do docs/manuais/animacao.md) sem abrir o vídeo inteiro — economiza contexto.
Uso: python3 tools/folha_quadros.py PASTA_QUADROS SAIDA.png X0 Y0 LARG ALT 110,135,150,160
  (PASTA_QUADROS = saída de --cargueiro-video=..., arquivos 0000.png, 0001.png, ...)
"""
import sys

from PIL import Image, ImageDraw

d_, out, x0, y0, w, h = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:7])
fr = list(map(int, sys.argv[7].split(',')))
cols = 4
rows = (len(fr) + cols - 1) // cols
sheet = Image.new('RGB', (w * cols, h * rows))
dr = ImageDraw.Draw(sheet)
for i, f in enumerate(fr):
    im = Image.open('%s/%04d.png' % (d_, f)).crop((x0, y0, x0 + w, y0 + h))
    sheet.paste(im, ((i % cols) * w, (i // cols) * h))
    dr.text(((i % cols) * w + 8, (i // cols) * h + 8), str(f), fill=(0, 0, 0))
sheet.save(out)
print(out)
