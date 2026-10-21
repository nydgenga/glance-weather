// SPDX-License-Identifier: 0BSD
// Pure presentation and parsing helpers; no Qt or network dependencies.

function condition(code, isDay) {
    var day = isDay !== 0;
    if (code === 0) return { icon: day ? "☀️" : "🌙", label: day ? "Clear sky" : "Clear night" };
    if (code === 1) return { icon: day ? "🌤️" : "🌙", label: "Mostly clear" };
    if (code === 2) return { icon: day ? "⛅" : "☁️", label: "Partly cloudy" };
    if (code === 3) return { icon: "☁️", label: "Overcast" };
    if (code === 45 || code === 48) return { icon: "🌫️", label: "Fog" };
    if (code === 51 || code === 53 || code === 55 || code === 56 || code === 57) return { icon: "🌦️", label: "Drizzle" };
    if (code === 61 || code === 63 || code === 65 || code === 66 || code === 67) return { icon: "🌧️", label: "Rain" };
    if (code === 71 || code === 73 || code === 75 || code === 77 || code === 85 || code === 86) return { icon: "🌨️", label: "Snow" };
    if (code === 80 || code === 81 || code === 82) return { icon: "🌦️", label: "Showers" };
    if (code === 95 || code === 96 || code === 99) return { icon: "⛈️", label: "Thunderstorms" };
    return { icon: "🌡️", label: "Weather unavailable" };
}

function moon(phase) {
    if (phase === null || phase === undefined || phase === "" ||
        !isFinite(Number(phase)) || Number(phase) < 0 || Number(phase) > 1) {
        return { icon: "🌙", label: "Phase unavailable", illumination: "" };
    }
    var p = ((Number(phase) % 1) + 1) % 1;
    // The principal phases (new, quarters, full) are short-lived events,
    // not entire one-eighth segments of the lunar month. The previous code
    // rounded p*8, incorrectly labelling waxing gibbous days as first quarter.
    // Phase is a fraction of the synodic cycle: 0=new, .25=first quarter,
    // .5=full, .75=last quarter. Narrow ±0.02-cycle windows name the
    // visually near-quarter days; they are NOT assertions of the exact
    // astronomical instant of each primary phase.
    var phase;
    if (p < 0.02 || p >= 0.98) phase = { icon: "🌑", label: "New Moon" };
    else if (p < 0.23) phase = { icon: "🌒", label: "Waxing Crescent" };
    else if (p < 0.27) phase = { icon: "🌓", label: "First Quarter" };
    else if (p < 0.48) phase = { icon: "🌔", label: "Waxing Gibbous" };
    else if (p < 0.52) phase = { icon: "🌕", label: "Full Moon" };
    else if (p < 0.73) phase = { icon: "🌖", label: "Waning Gibbous" };
    else if (p < 0.77) phase = { icon: "🌗", label: "Last Quarter" };
    else phase = { icon: "🌘", label: "Waning Crescent" };
    return { icon: phase.icon, label: phase.label,
        illumination: Math.round((1 - Math.cos(2 * Math.PI * p)) * 50) + "%" };
}

// Open-Meteo moon_phase is sampled at each forecast-local midnight.
// Approximate the fraction for the current local time by interpolating
// between today's and tomorrow's midnight samples. This improves phase
// labels near boundaries without bundling an ephemeris library.
// The API's model remains authoritative: interpolation is not an exact
// prediction of the moment of a quarter/full/new Moon.
function moonAtLocalTime(today, tomorrow, currentIso, localDate) {
    if (today === null || today === undefined || !isFinite(Number(today)) ||
        Number(today) < 0 || Number(today) > 1) return moon(null);
    var p0 = Number(today);
    if (tomorrow === null || tomorrow === undefined || !isFinite(Number(tomorrow)) ||
        Number(tomorrow) < 0 || Number(tomorrow) > 1) return moon(p0);
    if (typeof currentIso !== "string" || currentIso.slice(0, 10) !== localDate)
        return moon(p0);
    var match = /^\d{4}-\d\d-\d\dT(\d\d):(\d\d)/.exec(currentIso);
    if (!match) return moon(p0);
    var hh = Number(match[1]), mm = Number(match[2]);
    if (hh > 23 || mm > 59) return moon(p0);
    var p1 = Number(tomorrow);
    // Forward modular difference, including wraparound across new moon.
    var delta = (p1 - p0 + 1) % 1;
    // Reject implausibly large jumps from malformed data; use today's value.
    if (delta > 0.09) return moon(p0);
    var dayFraction = (hh * 60 + mm) / 1440;
    return moon((p0 + delta * dayFraction) % 1);
}

function clock(iso) {
    // Open-Meteo with timezone=auto provides ISO-8601 wall times in the
    // requested location. Deliberately do not parse with local Date, which
    // would silently apply the PC's timezone to a remote location.
    if (!iso || typeof iso !== "string") return "—";
    var m = /T(\d\d):(\d\d)/.exec(iso);
    if (!m) return "—";
    var hour = Number(m[1]);
    if (hour < 0 || hour > 23) return "—";
    return (hour % 12 || 12) + ":" + m[2] + (hour < 12 ? " AM" : " PM");
}

function dayName(dateString) {
    // Extract calendar date independent of both PC and forecast timezone.
    if (!dateString || !/^\d{4}-\d\d-\d\d$/.test(dateString)) return "—";
    var parts = dateString.split("-");
    var date = new Date(Date.UTC(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 12));
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getUTCDay()];
}

function degrees(v) {
    return typeof v === "number" && isFinite(v) ? Math.round(v) + "°" : "—";
}

function wind(v, unit) {
    return typeof v === "number" && isFinite(v) ? Math.round(v) + " " + (unit === "mph" ? "mph" : "km/h") : "—";
}

function makeForecast(payload) {
    if (!payload || !payload.current || !payload.daily || !Array.isArray(payload.daily.time))
        throw new Error("Incomplete forecast response");
    var c = payload.current;
    var d = payload.daily;
    if (typeof c.temperature_2m !== "number" || !Array.isArray(d.weather_code))
        throw new Error("Missing current temperature or daily conditions");
    var days = [];
    for (var i = 0; i < d.time.length; i++) {
        days.push({
            date: d.time[i],
            day: dayName(d.time[i]),
            icon: condition(d.weather_code[i], 1).icon,
            high: degrees(d.temperature_2m_max && d.temperature_2m_max[i]),
            low: degrees(d.temperature_2m_min && d.temperature_2m_min[i])
        });
    }
    var currentTime = c.time || "";
    var hourly = [];
    if (payload.hourly && Array.isArray(payload.hourly.time)) {
        var hourlyData = payload.hourly;
        for (var j = 0; j < hourlyData.time.length; j++) {
            // The API times are in the location's timezone; lexical ISO
            // comparisons preserve chronological ordering for this interval.
            if (hourlyData.time[j] <= currentTime) continue;
            if (hourly.length === 6) break;
            hourly.push({
                time: clock(hourlyData.time[j]),
                icon: condition(hourlyData.weather_code[j], hourlyData.is_day ? hourlyData.is_day[j] : 1).icon,
                temperature: degrees(hourlyData.temperature_2m[j]),
                rain: typeof hourlyData.precipitation_probability[j] === "number"
                    ? Math.round(hourlyData.precipitation_probability[j]) + "%" : "—"
            });
        }
    }
    return {
        current: {
            temperature: degrees(c.temperature_2m),
            feels: degrees(c.apparent_temperature),
            humidity: typeof c.relative_humidity_2m === "number" ? Math.round(c.relative_humidity_2m) + "%" : "—",
            wind: c.wind_speed_10m,
            condition: condition(c.weather_code, c.is_day),
            time: clock(currentTime)
        },
        days: days,
        today: {
            sunrise: clock(d.sunrise && d.sunrise[0]),
            sunset: clock(d.sunset && d.sunset[0]),
            moonrise: clock(d.moonrise && d.moonrise[0]),
            moonset: clock(d.moonset && d.moonset[0]),
            moon: moonAtLocalTime(d.moon_phase && d.moon_phase[0],
                                  d.moon_phase && d.moon_phase[1],
                                  currentTime, d.time[0])
        },
        hourly: hourly
    };
}
