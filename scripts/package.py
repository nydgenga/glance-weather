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
# Exact, reviewable release contents: never include arbitrary local notes,
# credentials, downloaded files, caches or untracked scratch files.
PLUGIN_FILES = (
    'LICENSE',
    'metadata.json',
    'contents/config/config.qml',
    'contents/config/main.xml',
    'contents/ui/RefreshPolicy.js',
    'contents/ui/Weather.js',
    'contents/ui/WeatherService.qml',
    'contents/ui/configGeneral.qml',
    'contents/ui/main.qml',
)
SOURCE_FILES = (
    '.github/workflows/glance-checks.yml',
    'CHANGELOG.md',
    'LICENSE',
    'README.md',
    'RELEASE_CHECKLIST.md',
    'screenshots/glance-weather.png',
    'scripts/package.py',
    'tests/test-api-backoff.js',
    'tests/test-layout.js',
    'tests/test-location-search.js',
    'tests/test-package.js',
    'tests/test-partial-response.js',
    'tests/test-refresh.js',
    'tests/test-release.js',
    'tests/test-stress.js',
    'tests/test-timestamps.js',
    'tests/test-weather.js',
) + tuple('package/' + file for file in PLUGIN_FILES)


def curated_paths(base: Path, names) -> list[Path]:
    paths = []
    for name in names:
        path = base / name
        if not path.is_file() or path.is_symlink():
            raise SystemExit(f'Missing or invalid release file: {name}')
        if not path.resolve().is_relative_to(base.resolve()):
            raise SystemExit(f'Release file outside source tree: {name}')
        paths.append(path)
    if len(set(paths)) != len(paths):
        raise SystemExit('Duplicate release file')
    return paths


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
    plugin_files = curated_paths(PACKAGE, PLUGIN_FILES)
    plasmoid = out / f'glance-weather-{version}.plasmoid'
    pack(plasmoid, plugin_files, PACKAGE)
    source = out / f'glance-weather-{version}-source.zip'
    source_files = curated_paths(ROOT, SOURCE_FILES)
    pack(source, source_files, ROOT)
    manifest = out / f'glance-weather-{version}-sha256.txt'
    manifest.write_text(''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n' for p in (plasmoid, source)))
    for p in (plasmoid, source, manifest):
        print(f'{p.name}: {p.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
