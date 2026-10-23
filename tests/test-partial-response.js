// SPDX-License-Identifier: 0BSD
// A missing optional hourly field must not discard current or daily weather.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const code = fs.readFileSync('package/contents/ui/Weather.js', 'utf8');
const weather = vm.createContext({ Date, Math, Number, Array, isFinite });
vm.runInContext(code, weather);

const payload = {
    current: { time: '2026-10-22T10:15', temperature_2m: 72, weather_code: 1,
        apparent_temperature: 69, relative_humidity_2m: 42, wind_speed_10m: 8,
        is_day: 1 },
    daily: { time: ['2026-10-22', '2026-10-23'], weather_code: [1, 3],
        temperature_2m_max: [76, 70], temperature_2m_min: [48, 50],
        sunrise: ['2026-10-22T07:22'], sunset: ['2026-10-22T18:11'] },
    hourly: { time: ['2026-10-22T10:00', '2026-10-22T11:00', '2026-10-22T12:00'],
        temperature_2m: [71, 73, 74], weather_code: [1, 2, 3],
        precipitation_probability: [0, 15, 40], is_day: [1, 1, 1] }
};
const copy = () => JSON.parse(JSON.stringify(payload));
function assertCore(report) {
    assert.equal(report.current.temperature, '72°');
    assert.equal(report.days.length, 2);
    assert.equal(report.days[0].high, '76°');
    assert.equal(report.days[0].low, '48°');
    assert.equal(report.today.sunrise, '7:22 AM');
}
// Baseline: populated time series still works and provides daily extrema times.
const complete = weather.makeForecast(copy());
assertCore(complete);
assert.equal(complete.hourly.length, 2);
assert.equal(complete.hourly[0].temperature, '73°');
assert.equal(complete.days[0].highTime, '12:00 PM');
assert.equal(complete.days[0].lowTime, '10:00 AM');

// Missing arrays: preserve the useful forecast; report unsupported hourly
// values instead of crashing or pretending there was a valid reading.
for (const field of ['temperature_2m', 'weather_code', 'precipitation_probability', 'is_day']) {
    const p = copy();
    delete p.hourly[field];
    const r = weather.makeForecast(p);
    assertCore(r);
    assert.equal(r.hourly.length, 2);
    if (field === 'temperature_2m') {
        assert.equal(r.hourly[0].temperature, '—');
        assert.equal(r.days[0].highTime, '—');
        assert.equal(r.days[0].lowTime, '—');
    }
    if (field === 'weather_code') assert.equal(r.hourly[0].icon, '🌡️');
    if (field === 'precipitation_probability') assert.equal(r.hourly[0].rain, '—');
}
// Null/wrong-type arrays, short arrays, and invalid individual samples.
for (const field of ['temperature_2m', 'weather_code', 'precipitation_probability']) {
    const p = copy();
    p.hourly[field] = null;
    assertCore(weather.makeForecast(p));
    p.hourly[field] = {};
    assertCore(weather.makeForecast(p));
}
const truncated = copy();
truncated.hourly.temperature_2m = [71, null];
truncated.hourly.weather_code = [1];
truncated.hourly.precipitation_probability = [0, null, Infinity];
const partial = weather.makeForecast(truncated);
assertCore(partial);
assert.equal(partial.hourly[0].temperature, '—');
assert.equal(partial.hourly[1].temperature, '—');
assert.equal(partial.hourly[0].rain, '—');
assert.equal(partial.hourly[1].rain, '—');
assert.equal(partial.hourly[0].icon, '🌡️');

// Malformed hourly timestamps are skipped instead of creating bogus columns.
const malformed = copy();
malformed.hourly.time = [null, 'nonsense', 123, '2026-10-22T11:00', '2026-10-22T12:00'];
const cleaned = weather.makeForecast(malformed);
assertCore(cleaned);
assert.equal(cleaned.hourly.length, 2);
assert.equal(cleaned.hourly[0].shortTime, '11 AM');
// If even the hourly timestamps are unavailable, current/daily still render.
const noHours = copy();
noHours.hourly = { time: null };
assertCore(weather.makeForecast(noHours));
assert.equal(weather.makeForecast(noHours).hourly.length, 0);
// But genuinely missing required core data remains a parse failure.
const noCurrent = copy();
delete noCurrent.current;
assert.throws(() => weather.makeForecast(noCurrent), /Incomplete forecast/);
const noDaily = copy();
delete noDaily.daily.weather_code;
assert.throws(() => weather.makeForecast(noDaily), /Missing current temperature or daily conditions/);
console.log('Optional hourly series tolerate absent, malformed and partial fields');
