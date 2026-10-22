// SPDX-License-Identifier: 0BSD
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const policy = vm.createContext({});
vm.runInContext(fs.readFileSync('package/contents/ui/RefreshPolicy.js', 'utf8'), policy);
const { shouldRefresh, requestIsStalled } = policy;
const now = 1770000000000;
const minute = 60 * 1000;
// First launch and normal cadence.
assert.equal(shouldRefresh(now, 0, 0, false, false), true);
assert.equal(shouldRefresh(now, now - 29 * minute, now - 29 * minute, false, false), false);
assert.equal(shouldRefresh(now, now - 30 * minute, now - 30 * minute, false, false), true);
assert.equal(shouldRefresh(now, now - 31 * minute, now, true, false), false);
// If a request failed during an outage, do not wait another 30 minutes.
assert.equal(shouldRefresh(now, now - 60 * minute, now - minute, false, true), false);
assert.equal(shouldRefresh(now, now - 60 * minute, now - 2 * minute, false, true), true);
assert.equal(shouldRefresh(now, 0, now - 2 * minute, false, true), true);
assert.equal(shouldRefresh(now, now - minute, now, false, false), false);
// Resume from hours of sleep, even if the animation timer had never ticked.
assert.equal(shouldRefresh(now, now - 8 * 60 * minute, now - 8 * 60 * minute, false, false), true);
assert.equal(shouldRefresh(now, now - 8 * 60 * minute, now - 5 * minute, false, true), true);
// System clock adjustments should not strand the scheduler.
assert.equal(shouldRefresh(now, now + minute, now + minute, false, false), true);
assert.equal(shouldRefresh(now, now - minute, now + minute, false, true), true);
assert.equal(shouldRefresh(NaN, 0, 0, false, false), false);
// In-flight network requests from before suspend get cancelled on wake.
assert.equal(requestIsStalled(now, now - 20 * 1000, true), false);
assert.equal(requestIsStalled(now, now - 25 * 1000, true), true);
assert.equal(requestIsStalled(now, now - 5 * 60 * minute, true), true);
assert.equal(requestIsStalled(now, now + minute, true), true);
assert.equal(requestIsStalled(now, now - 25 * 1000, false), false);
// Structural integration: Qt continues to provide the watchdog ticks.
const main = fs.readFileSync('package/contents/ui/main.qml', 'utf8');
const svc = fs.readFileSync('package/contents/ui/WeatherService.qml', 'utf8');
assert.match(main, /import "RefreshPolicy.js" as RefreshPolicy/);
assert.match(main, /interval: 60000; repeat: true; running: root.validLocation; onTriggered: root.refreshIfDue\(\)/);
assert.doesNotMatch(main, /interval: 1800000; repeat: true/);
assert.match(main, /RefreshPolicy\.requestIsStalled/);
assert.match(svc, /lastAttemptMs = Date\.now\(\)/);
assert.match(svc, /lastSuccessMs = Date\.now\(\)/);
// Moon-field 400 fallback has an independent timeout from the first HTTP call.
assert.match(svc, /signal requestStarted\(\)/);
assert.match(svc, /lastAttemptMs = Date\.now\(\);\s*requestStarted\(\)/);
assert.match(main, /function onRequestStarted\(\) \{ requestTimeout\.restart\(\) \}/);
assert.match(main, /id: requestTimeout/);
// Generic status alone is insufficient to diagnose failures after waking.
assert.match(main, /QQC2\.ToolTip\.text: weatherService\.error\.length > 0/);
assert.match(svc, /console\.warn\("Glance Weather: " \+ error\)/);
assert.match(svc, /No HTTP response \(check network or TLS\)/);
assert.match(main, /acceptedButtons: Qt\.NoButton/);
// Humidity remains a droplet; hourly precipitation gets a distinguishable umbrella.
assert.match(main, /text: "💧 " \+ root.forecast.current.humidity/);
assert.match(main, /: "☔" \+ modelData.rain/);
assert.doesNotMatch(main, /: "💧" \+ modelData.rain/);
console.log('Suspend/reconnect retry policy, watchdog, and distinct symbols passed');
