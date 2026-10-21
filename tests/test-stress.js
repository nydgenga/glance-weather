// SPDX-License-Identifier: 0BSD
// Stress test the forecast data that drive narrow QML cells; this cannot
// substitute for actual glyph layout tests in a Plasma desktop session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const sandbox = { Date, Math, Number, Array, isFinite };
vm.createContext(sandbox);
vm.runInContext(fs.readFileSync('package/contents/ui/Weather.js', 'utf8'), sandbox);

// Every published Open-Meteo/WMO weather code our client recognizes,
// both day and night. All outputs should have valid icon and label strings.
const codes = [0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,82,85,86,95,96,99];
for (const code of codes) {
    for (const isDay of [0, 1]) {
        const c = sandbox.condition(code, isDay);
        assert.equal(typeof c.icon, 'string');
        assert.ok(c.icon.length > 0);
        assert.ok(c.label.length > 0);
        assert.notEqual(c.label, 'Weather unavailable');
    }
}
assert.equal(sandbox.condition(999, 1).label, 'Weather unavailable');

// A full set of abnormal but structurally valid weather inputs. The view
// should still be able to display seven-day and six-hour content.
const today = '2048-02-25';
const dailyTimes = Array.from({length:7},(_,i)=>
    new Date(Date.UTC(2048,1,25+i)).toISOString().slice(0,10));
const hourlyTimes = Array.from({length:8},(_,i)=>`2048-02-25T${String(12+i).padStart(2,'0')}:00`);
const fixture = {
    current: {
        temperature_2m:-123.4, apparent_temperature:-130.7,
        relative_humidity_2m:100, wind_speed_10m:115.5, weather_code:95,
        is_day:0, time:'2048-02-25T12:00'
    },
    daily: {
        time:dailyTimes, weather_code:[0,3,48,67,75,86,99],
        temperature_2m_max:[123.9,-123,110,-110,99,0,50],
        temperature_2m_min:[-127,-110,-100,-30,-2,5,25],
        sunrise:['2048-02-25T06:02'],sunset:['2048-02-25T18:04'],
        moonrise:['2048-02-25T15:06'],moonset:['2048-02-25T03:02'],
        moon_phase:[0.49,0.525]
    },
    hourly: {
        time:hourlyTimes, weather_code:[0,1,48,99,66,85,3,2],
        temperature_2m:[-123,123,0,-50,70,-95,66,102],
        precipitation_probability:[0,100,99,50,5,75,90,10],
        is_day:[0,1,1,0,1,1,0,0]
    }
};
const out=sandbox.makeForecast(fixture);
assert.equal(out.current.temperature,'-123°');
assert.equal(out.current.feels,'-131°');
assert.equal(out.days.length,7);
assert.equal(out.hourly.length,6);
assert.equal(out.days[0].high,'124°');
assert.equal(out.days[0].low,'-127°');
assert.equal(out.hourly[0].rain,'100%');
assert.equal(out.hourly[0].temperature,'123°');
assert.equal(out.hourly[2].icon,'⛈️');
assert.equal(out.today.moon.label,'Full Moon');
for (const cell of [...out.days,...out.hourly]) {
    assert.ok(cell.icon.length > 0);
    assert.ok(cell.temperature || cell.high);
}
console.log(`Stress fixtures passed: ${codes.length * 2} icon cases, 7 days, 6 hours, extreme temperatures and 100% rain`);
