"""Erzeugt docs/index.html (eigenständige Webseite für GitHub Pages) aus index.html.
index.html ist für das Claude-Artifact ohne <html>/<head>-Gerüst geschrieben; hier wird es ergänzt."""
import pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'index.html').read_text(encoding='utf-8')
cut = src.index('</style>') + len('</style>')
head, body = src[:cut], src[cut:]
page = ('<!doctype html>\n<html lang="de">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="description" content="Valora City – ein Open-World-Spiel im Browser.">\n'
        + head + '\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
out = root / 'docs'
out.mkdir(exist_ok=True)
(out / 'index.html').write_text(page, encoding='utf-8')
(out / '.nojekyll').write_text('', encoding='utf-8')
print('docs/index.html geschrieben,', len(page), 'Zeichen')
