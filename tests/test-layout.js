// SPDX-License-Identifier: 0BSD
// Static budget check for the v0.1.3 compact layout. This does not replace
// testing QML against Plasma's runtime frame and font metrics.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const text = fs.readFileSync('package/contents/ui/main.qml', 'utf8');
assert.match(text, /height: 64\b/); // current conditions
assert.match(text, /height: 73\b/); // daily forecast
assert.match(text, /height: root\.showAstronomy \? 56 : 0/);
assert.match(text, /spacing: 3\s+\/\/ Header:/);
assert.match(text, /interactive: contentHeight > height \+ 1/);
assert.match(text, /QQC2\.ScrollBar\.vertical: QQC2\.ScrollBar/);
const sections = [21, 64, 18, 1, 73, 1, 56, 22];
const height = sections.reduce((sum, value) => sum + value, 0) + 7 * 3 + 16;
assert.ok(height <= 295, `Default nominal body height ${height} exceeds 295`);
const metadata = JSON.parse(fs.readFileSync('package/metadata.json'));
assert.equal(metadata.KPlugin.Version, '0.1.3');
assert.equal(metadata.KPlugin.Id, 'com.github.nydgenga.glanceweather');
console.log(`Nominal compact body height: ${height}px including internal padding`);
