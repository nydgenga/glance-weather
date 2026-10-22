// SPDX-License-Identifier: 0BSD
// Static coverage: timestamp distinction and stale-data diagnostic preservation.
// This staged prototype is not approved or deployed on a Plasma session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const qml = fs.readFileSync(path.join(root, 'package/contents/ui/main.qml'), 'utf8');
const svc = fs.readFileSync(path.join(root, 'package/contents/ui/WeatherService.qml'), 'utf8');
assert.match(svc, /property double lastSuccessMs: 0/);
assert.match(svc, /lastSuccessMs = Date\.now\(\)/);
assert.match(qml, /function timestampTooltip\(\)/);
assert.match(qml, /weatherService\.hasData \|\| weatherService\.lastSuccessMs <= 0/);
assert.match(qml, /Qt\.formatDateTime\(new Date\(weatherService\.lastSuccessMs\)\)/);
assert.match(qml, /i18n\("Weather data as of %1 \(forecast location time\)"/);
assert.match(qml, /i18n\("Last fetched: %1 \(computer time\)"/);
assert.match(qml, /i18n\("As of %1", root\.forecast\.current\.time\)/);
assert.doesNotMatch(qml, /i18n\("Updated %1", root\.forecast\.current\.time\)/);
assert.match(qml, /QQC2\.ToolTip\.visible: statusHover\.containsMouse && weatherService\.hasData/);
assert.match(qml, /QQC2\.ToolTip\.text: weatherService\.error\.length > 0/);
assert.match(qml, /i18n\("Error: %1", weatherService\.error\)/);
assert.match(qml, /i18n\("Automatic retry is enabled\."\)/);
// Refresh scheduling is untouched by the timestamp presentation.
assert.match(qml, /interval: 60000; repeat: true; running: root\.validLocation/);
console.log('Timestamp tooltip and error preservation checks passed');
