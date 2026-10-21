// SPDX-License-Identifier: 0BSD
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const code = fs.readFileSync('package/contents/ui/Weather.js', 'utf8');
const weather = vm.createContext({ Date, Math, Number, Array, isFinite });
vm.runInContext(code, weather);
assert.strictEqual(weather.condition(0, 1).icon, '☀️');
assert.strictEqual(weather.condition(0, 0).icon, '🌙');
assert.strictEqual(weather.condition(0, 0).label, 'Clear night');
assert.strictEqual(weather.condition(95, 1).icon, '⛈️');
assert.strictEqual(weather.moon(0.25).label, 'First Quarter');
assert.strictEqual(weather.moon(0.29).label, 'Waxing Gibbous');
assert.strictEqual(weather.moon(0.33).icon, '🌔');
assert.strictEqual(weather.moon(0.71).label, 'Waning Gibbous');
assert.strictEqual(weather.moon(0.75).label, 'Last Quarter');
assert.strictEqual(weather.moon(0.92).label, 'Waning Crescent');
assert.strictEqual(weather.moon(0.5).label, 'Full Moon');
assert.strictEqual(weather.moon(null).label, 'Phase unavailable');
assert.strictEqual(weather.moon('').label, 'Phase unavailable');
assert.strictEqual(weather.moon(-0.1).label, 'Phase unavailable');
assert.strictEqual(weather.moon(1.1).label, 'Phase unavailable');
assert.strictEqual(weather.moon(0).label, 'New Moon');
assert.strictEqual(weather.moon(1).label, 'New Moon');
assert.strictEqual(weather.moon(0.12).label, 'Waxing Crescent');
assert.strictEqual(weather.moon(0.37).label, 'Waxing Gibbous');
assert.strictEqual(weather.moon(0.62).label, 'Waning Gibbous');
assert.strictEqual(weather.moon(0.87).label, 'Waning Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T12:00', '2026-10-18').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T00:00', '2026-10-18').label, 'Waxing Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T23:59', '2026-10-18').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.47, 0.51, '2026-10-26T19:00', '2026-10-26').label, 'Full Moon');
assert.strictEqual(weather.moonAtLocalTime(0.72, 0.76, '2026-11-01T20:00', '2026-11-01').label, 'Last Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.96, 0.01, '2026-11-09T15:00', '2026-11-09').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.99, 0.02, '2026-11-09T23:59', '2026-11-09').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.30, 0.34, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, null, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, 0.37, '2026-10-21T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, 0.99, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
for (let p = 0; p < 1; p += 0.001) {
    const phase = weather.moon(p);
    assert.ok(phase.icon.length > 0 && phase.label.length > 0);
    assert.ok(parseFloat(phase.illumination) >= 0 && parseFloat(phase.illumination) <= 100);
}

assert.strictEqual(weather.clock('2026-10-20T00:07'), '12:07 AM');
assert.strictEqual(weather.clock('2026-10-20T18:05'), '6:05 PM');
assert.strictEqual(weather.clock(null), '—');
assert.strictEqual(weather.dayName('2026-10-20'), 'Tue');
const payload = {
    current: { temperature_2m: 60.3, apparent_temperature: 51.2, weather_code: 0,
        relative_humidity_2m: 39, wind_speed_10m: 11.4, is_day: 1, time: '2026-10-20T16:15' },
    daily: { time: ['2026-10-20', '2026-10-21'], weather_code: [0, 61],
        temperature_2m_max: [71.2, 68], temperature_2m_min: [47, 49],
        sunrise: ['2026-10-20T07:05'], sunset: ['2026-10-20T17:59'],
        moonrise: [null], moonset: ['2026-10-20T19:25'], moon_phase: [0.24, 0.26] },
    hourly: { time: ['2026-10-20T16:00', '2026-10-20T17:00', '2026-10-20T18:00'],
        weather_code: [0, 1, 3], temperature_2m: [60, 58, 56],
        precipitation_probability: [0, 10, 35], is_day: [1, 1, 0] }
};
const report = weather.makeForecast(payload);
assert.strictEqual(report.current.temperature, '60°');
assert.strictEqual(report.days.length, 2);
assert.strictEqual(report.today.sunrise, '7:05 AM');
assert.strictEqual(report.today.moonrise, '—');
assert.strictEqual(report.today.moon.label, 'First Quarter');
assert.strictEqual(report.hourly.length, 2);
assert.strictEqual(report.hourly[0].time, '5:00 PM');
console.log('Weather.js: phase boundaries, time interpolation, cycle sweep, and forecast parsing passed');
