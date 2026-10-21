// SPDX-License-Identifier: 0BSD
// Structural/budget checks. QML rendering still needs a real Plasma session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const main = fs.readFileSync('package/contents/ui/main.qml', 'utf8');
const service = fs.readFileSync('package/contents/ui/WeatherService.qml', 'utf8');
const settings = fs.readFileSync('package/contents/ui/configGeneral.qml', 'utf8');
const xml = fs.readFileSync('package/contents/config/main.xml', 'utf8');
const metadata = JSON.parse(fs.readFileSync('package/metadata.json', 'utf8'));
assert.equal(metadata.KPlugin.Version, '0.1.7');
assert.equal(metadata.KPlugin.Id, 'com.github.nydgenga.glanceweather');
assert.match(main, /height: 416\b/);
assert.match(main, /implicitHeight: 416\b/);
assert.match(main, /font\.pixelSize: 18/); // hero high/low temperatures
assert.match(main, /text: i18n\("Next six hours"\)/);
assert.match(main, /model: root\.forecast\.hourly \|\| \[\]/);
assert.match(main, /root\.forecast\.days\.slice\(0, 7\)/);
assert.match(main, /Weather\.wind\(root\.forecast\.current\.wind, root\.windUnit\)/);
assert.match(main, /root\.forecast\.current\.humidity/);
assert.doesNotMatch(main, /forecastDays|showHumidity|showWind|hourlyPopup/);
assert.doesNotMatch(settings + xml, /forecastDays|showHumidity|showWind/);
assert.match(service, /"forecast_days=7"/);
assert.doesNotMatch(service, /dayCount/);
assert.match(main, /showAstronomy/);
const rows = [21, 64, 18, 1, 88, 1, 85, 1, 56, 22];
const budget = rows.reduce((a, b) => a + b, 0) + (rows.length - 1) * 3 + 16;
assert.equal(budget, 400);
assert.ok(budget + 12 <= 416); // including desired frame breathing room
console.log(`Static seven-day/six-hour layout budget: ${budget}px inside 416px frame`);
