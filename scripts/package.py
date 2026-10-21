#!/usr/bin/env python3
"""Build reproducible Glance Weather release archives using Python stdlib only."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / 'package'
FIXED_TIME = (2020, 1, 1, 0, 0, 0)
SOURCE_EXCLUDE = {'dist', '.git', '__pycache__'}


def pack(archive: Path, paths, base: Path) -> None:
    archive.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(paths, key=lambda p: p.relative_to(base).as_posix()):
            name = path.relative_to(base).as_posix()
            item = zipfile.ZipInfo(filename=name, date_time=FIXED_TIME)
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = 0o100644 << 16
            z.writestr(item, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def main() -> None:
    args = argparse.ArgumentParser()
    args.add_argument('--out', type=Path, default=ROOT / 'dist', help='Output directory')
    out = args.parse_args().out
    meta = json.loads((PACKAGE / 'metadata.json').read_text())
    version = meta['KPlugin']['Version']
    if meta['KPlugin']['Id'] != 'com.github.nydgenga.glanceweather':
        raise SystemExit('Unexpected plugin ID')
    plugin_files = [p for p in PACKAGE.rglob('*') if p.is_file()]
    if not any(p.name == 'metadata.json' for p in plugin_files):
        raise SystemExit('Missing package metadata.json')
    plasmoid = out / f'glance-weather-{version}.plasmoid'
    pack(plasmoid, plugin_files, PACKAGE)
    source = out / f'glance-weather-{version}-source.zip'
    source_files = [p for p in ROOT.rglob('*') if p.is_file() and not any(s in SOURCE_EXCLUDE for s in p.relative_to(ROOT).parts)]
    pack(source, source_files, ROOT)
    manifest = out / f'glance-weather-{version}-sha256.txt'
    manifest.write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in (plasmoid, source)))
    for p in (plasmoid, source, manifest):
        print(f'{p.name}: {p.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
