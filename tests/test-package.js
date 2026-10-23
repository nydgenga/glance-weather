// SPDX-License-Identifier: 0BSD
// Packaging is explicitly allowlisted, deterministic, and rejects missing files.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'glance-package-'));
try {
    const source = path.join(work, 'source');
    fs.cpSync(root, source, {recursive:true, filter:p=>!p.split(path.sep).includes('dist')});
    // Simulate local secrets or scratch files appearing in the checkout.
    fs.writeFileSync(path.join(source,'private-credentials.env'), 'SECRET_SENTINEL');
    fs.writeFileSync(path.join(source,'package/contents/ui/local-scratch.txt'), 'SECRET_SENTINEL');
    fs.writeFileSync(path.join(source,'tests/temporary-test.js'), 'SECRET_SENTINEL');
    function build(out) {
        const r = spawnSync('python3', ['scripts/package.py','--out',out], {cwd:source,encoding:'utf8'});
        assert.equal(r.status, 0, r.stderr || r.stdout);
    }
    const one = path.join(work,'a');
    const two = path.join(work,'b');
    build(one); build(two);
    const metadata = JSON.parse(fs.readFileSync(path.join(source,'package/metadata.json'),'utf8'));
    const v = metadata.KPlugin.Version;
    for (const name of [`glance-weather-${v}.plasmoid`,`glance-weather-${v}-source.zip`,`glance-weather-${v}-sha256.txt`]) {
        const a = fs.readFileSync(path.join(one,name));
        const b = fs.readFileSync(path.join(two,name));
        assert.ok(a.equals(b), `${name} differs between deterministic builds`);
        assert.equal(a.includes(Buffer.from('SECRET_SENTINEL')),false);
    }
    const code = `import sys,zipfile
for target in sys.argv[1:]:
 with zipfile.ZipFile(target) as z:
  names = set(z.namelist())
  assert all(not (n.endswith('private-credentials.env') or n.endswith('local-scratch.txt') or n.endswith('temporary-test.js')) for n in names)
  assert z.testzip() is None
`;
    const check = spawnSync('python3', ['-c',code,
        path.join(one,`glance-weather-${v}.plasmoid`),
        path.join(one,`glance-weather-${v}-source.zip`)],{encoding:'utf8'});
    assert.equal(check.status,0,check.stderr);
    // Missing required source prevents an incomplete release.
    fs.rmSync(path.join(source,'tests/test-weather.js'));
    const missing=spawnSync('python3',['scripts/package.py','--out',path.join(work,'missing')],{cwd:source,encoding:'utf8'});
    assert.notEqual(missing.status,0);
    assert.match(missing.stderr+missing.stdout,/Missing or invalid release file/);
} finally {fs.rmSync(work,{recursive:true,force:true});}
console.log('Curated package contents, deterministic archives, missing-file checks passed');
