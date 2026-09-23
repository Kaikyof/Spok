#!/usr/bin/env python3
"""Собирает platform-console-mvp.html в один файл со встроенными макетами —
чтобы отправить человеку, у которого нет репозитория.

    python3 docs/build-single.py

Результат: docs/platform-console-mvp-single.html (~5 МБ, в git не хранится).
"""
import base64, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'platform-console-mvp.html')
DST = os.path.join(HERE, 'platform-console-mvp-single.html')

def inline(m):
    path = os.path.join(HERE, 'console-screens', m.group(1) + '.png')
    if not os.path.exists(path):
        sys.exit('нет файла: ' + path)
    with open(path, 'rb') as f:
        return 'src="data:image/png;base64,%s"' % base64.b64encode(f.read()).decode()

with open(SRC, encoding='utf-8') as f:
    html = f.read()
html, n = re.subn(r'src="console-screens/([0-9a-z]+)\.png"', inline, html)
with open(DST, 'w', encoding='utf-8') as f:
    f.write(html)
print('встроено макетов: %d · %s · %.1f МБ' % (n, os.path.basename(DST), os.path.getsize(DST) / 1e6))
