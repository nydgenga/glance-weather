// SPDX-License-Identifier: 0BSD
// Static budget check for the v0.1.6 compact layout. This does not replace
// testing QML against Plasma's runtime frame and font metrics.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const text = fs.readFileSync('package/contents/ui/main.qml', 'utf8');
assert.match(text, /height: 64\b/); // current conditions
assert.match(text, /height: 85\b/); // daily forecast with extra space before the sun/moon divider
assert.match(text, /height: root\.showAstronomy \? 56 : 0/);
assert.match(text, /spacing: 3\s+\/\/ Header:/);
assert.match(text, /interactive: contentHeight > height \+ 1/);
assert.ok(text.includes('readonly property int naturalHeight: 320 - (showAstronomy ? 0 : 60)'));
assert.ok(text.includes('- ((showHumidity || showWind) ? 0 : 21)'));
assert.ok(text.includes('height: naturalHeight'));
assert.ok(text.includes('implicitHeight: naturalHeight'));
assert.ok(text.includes('Layout.preferredHeight: Math.max(180, bodyColumn.implicitHeight + 31)'));
const naturalHeight = (astronomy, hasDetails) => 320 - (astronomy ? 0 : 60) - (hasDetails ? 0 : 21);
assert.equal(naturalHeight(true, true), 320);
assert.equal(naturalHeight(false, true), 260);
assert.equal(naturalHeight(true, false), 299);
assert.equal(naturalHeight(false, false), 239);
assert.match(text, /QQC2\.ScrollBar\.vertical: QQC2\.ScrollBar/);
assert.match(text, /smallSize: panel\.width < 390 \? 12 : 13/);
assert.match(text, /text: i18n\("Rise %1", root\.forecast\.today\.sunrise\); color: panel\.muted; font\.pixelSize: 12/);
const sections = [21, 64, 18, 1, 85, 1, 56, 22];
const height = sections.reduce((sum, value) => sum + value, 0) + 7 * 3 + 16;
assert.ok(height <= 308, `Default nominal body height ${height} exceeds 308`);
const metadata = JSON.parse(fs.readFileSync('package/metadata.json'));
assert.equal(metadata.KPlugin.Version, '0.1.6');
assert.equal(metadata.KPlugin.Id, 'com.github.nydgenga.glanceweather');
assert.ok(height >= 300, "Spacing budget unexpectedly reduced");
console.log(`Nominal compact body height: ${height}px including internal padding`);
