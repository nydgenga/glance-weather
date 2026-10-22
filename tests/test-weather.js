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
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T12:00', '2026-10-18').label, 'Waxing Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.265, '2026-10-18T18:00', '2026-10-18').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T00:00', '2026-10-18').label, 'Waxing Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.22, 0.26, '2026-10-18T23:59', '2026-10-18').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.47, 0.51, '2026-10-26T19:00', '2026-10-26').label, 'Full Moon');
assert.strictEqual(weather.moonAtLocalTime(0.72, 0.76, '2026-11-01T20:00', '2026-11-01').label, 'Last Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.96, 0.01, '2026-11-09T15:00', '2026-11-09').label, 'Waning Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.96, 0.01, '2026-11-09T23:59', '2026-11-09').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.99, 0.02, '2026-11-09T23:59', '2026-11-09').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.30, 0.34, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, null, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, 0.37, '2026-10-21T21:00', '2026-10-20').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.33, 0.99, '2026-10-20T21:00', '2026-10-20').label, 'Waxing Gibbous');
// Guard the noon-vs-midnight regression. 0.245 is the value at local noon;
// at 00:00 the Moon is still in the preceding phase.
assert.strictEqual(weather.moonAtLocalTime(0.245, 0.285, '2035-03-20T00:00', '2035-03-20').label, 'Waxing Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.245, 0.285, '2035-03-20T12:00', '2035-03-20').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.245, 0.285, '2035-03-20T23:59', '2035-03-20').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime(0.48, 0.52, '2047-04-09T00:00', '2047-04-09').label, 'Waxing Gibbous');
assert.strictEqual(weather.moonAtLocalTime(0.48, 0.52, '2047-04-09T12:00', '2047-04-09').label, 'Full Moon');
assert.strictEqual(weather.moonAtLocalTime(0.98, 0.02, '2032-06-15T00:00', '2032-06-15').label, 'Waning Crescent');
assert.strictEqual(weather.moonAtLocalTime(0.98, 0.02, '2032-06-15T12:00', '2032-06-15').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.98, 0.02, '2032-06-15T23:59', '2032-06-15').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.25, '', '2035-03-20T09:00', '2035-03-20').label, 'First Quarter');
assert.strictEqual(weather.moonAtLocalTime('', 0.28, '2035-03-20T09:00', '2035-03-20').label, 'Phase unavailable');
assert.strictEqual(weather.moonAtLocalTime(0.98, 0.13, '2035-03-20T09:00', '2035-03-20').label, 'New Moon');
assert.strictEqual(weather.moonAtLocalTime(0.25, 0.29, '2035-03-21T09:00', '2035-03-20').label, 'First Quarter');

for (let p = 0; p < 1; p += 0.001) {
    const phase = weather.moon(p);
    assert.ok(phase.icon.length > 0 && phase.label.length > 0);
    assert.ok(parseFloat(phase.illumination) >= 0 && parseFloat(phase.illumination) <= 100);
}

assert.strictEqual(weather.clock('2026-10-20T00:07'), '12:07 AM');
assert.strictEqual(weather.clock('2026-10-20T18:05'), '6:05 PM');
assert.strictEqual(weather.clock(null), '—');
assert.strictEqual(weather.hourLabel('2026-10-20T00:00'), '12 AM');
assert.strictEqual(weather.hourLabel('2026-10-20T12:00'), '12 PM');
assert.strictEqual(weather.hourLabel('2026-10-20T19:00'), '7 PM');
assert.strictEqual(weather.hourLabel('not a date'), '—');
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
assert.strictEqual(report.hourly[0].shortTime, '5 PM');
assert.strictEqual(report.hourly[0].rain, '10%');

// A full seven-day response and hourly samples spanning midnight.
const full = JSON.parse(JSON.stringify(payload));
full.daily.time = ['2026-10-20','2026-10-21','2026-10-22','2026-10-23','2026-10-24','2026-10-25','2026-10-26'];
full.daily.weather_code = [0,1,2,3,61,71,95];
full.daily.temperature_2m_max = [66,67,68,69,70,71,72];
full.daily.temperature_2m_min = [41,42,43,44,45,46,47];
full.hourly.time = Array.from({length: 10}, (_, i) =>
    `2026-10-${i < 8 ? '20' : '21'}T${String((16 + i) % 24).padStart(2,'0')}:00`);
full.hourly.weather_code = new Array(10).fill(0);
full.hourly.temperature_2m = new Array(10).fill(55);
full.hourly.precipitation_probability = [0,5,10,15,20,25,30,35,40,45];
full.hourly.is_day = new Array(10).fill(0);
const reportFull = weather.makeForecast(full);
assert.strictEqual(reportFull.days.length, 7);
assert.strictEqual(reportFull.days[6].day, 'Mon');
assert.strictEqual(reportFull.hourly.length, 6);
assert.strictEqual(reportFull.hourly[0].shortTime, '5 PM');
assert.strictEqual(reportFull.hourly[5].shortTime, '10 PM');
// The hourly probability feed is optional; absent data should show —.
delete full.hourly.precipitation_probability;
assert.strictEqual(weather.makeForecast(full).hourly[0].rain, '—');
console.log('Weather.js: phase boundaries, time interpolation, cycle sweep, and forecast parsing passed');

// Daily high/low timing prototype: extract from the *existing* 168-hour data.
// The daily aggregates can differ from individual hourly extrema, so the
// tooltip deliberately labels these as approximate hours.
const clockHour = iso => `${iso.slice(0,10)}T${iso.slice(11)}`;
const sevenDate = ['2026-10-20','2026-10-21','2026-10-22','2026-10-23','2026-10-24','2026-10-25','2026-10-26'];
const sevenHours = [];
for (const day of sevenDate)
    for (let hh = 0; hh < 24; hh++)
        sevenHours.push(`${day}T${String(hh).padStart(2, '0')}:00`);
const sevenTemps = sevenHours.map((_, i) => 10 + 10 * Math.sin((i % 24 - 6) * Math.PI / 12));
const extremeFixture = JSON.parse(JSON.stringify(full));
extremeFixture.daily.time = sevenDate;
extremeFixture.hourly.time = sevenHours;
extremeFixture.hourly.temperature_2m = sevenTemps;
extremeFixture.hourly.weather_code = sevenHours.map(() => 0);
extremeFixture.hourly.precipitation_probability = sevenHours.map(() => 0);
extremeFixture.hourly.is_day = sevenHours.map(() => 1);
const extremeResult = weather.makeForecast(extremeFixture);
assert.strictEqual(extremeResult.days.length, 7);
for (const day of extremeResult.days) {
    assert.strictEqual(day.highTime, '12:00 PM');
    assert.strictEqual(day.lowTime, '12:00 AM');
}
// Multiple equal maxima: earliest matching hour, independent of array order.
const ties = weather.hourlyExtremeTimes({
    time: ['2026-10-20T16:00','2026-10-20T14:00','2026-10-20T05:00',
           '2026-10-20T06:00','2026-10-21T10:00','invalid'],
    temperature_2m: [30,30,-2,-2,7,50]
});
assert.strictEqual(ties['2026-10-20'].highIso, '2026-10-20T14:00');
assert.strictEqual(ties['2026-10-20'].lowIso, '2026-10-20T05:00');
assert.strictEqual(ties['2026-10-21'].highIso, '2026-10-21T10:00');
assert.strictEqual(Object.keys(ties).length, 2);
// Missing or malformed samples never create misleading times.
assert.strictEqual(Object.keys(weather.hourlyExtremeTimes(null)).length, 0);
const partial = JSON.parse(JSON.stringify(extremeFixture));
delete partial.hourly;
assert.strictEqual(weather.makeForecast(partial).days[0].highTime, '—');
assert.strictEqual(weather.makeForecast(partial).days[0].lowTime, '—');
const invalidTimes = weather.hourlyExtremeTimes({
    time: ['2026-10-20T00:00','2026-10-20T01:00','2026-10-20T02:00'],
    temperature_2m: [null, NaN, Infinity]
});
assert.strictEqual(Object.keys(invalidTimes).length, 0);
console.log('Seven-day hourly high/low timing and missing-data checks passed');
