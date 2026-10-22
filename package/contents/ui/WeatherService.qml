// SPDX-License-Identifier: 0BSD
import QtQuick
import "Weather.js" as Weather

QtObject {
    id: service
    property bool busy: false
    property bool hasData: false
    property string error: ""
    // Valid placeholder structure prevents unloaded/hidden delegates from
    // evaluating undefined nested properties while the first request runs.
    property var data: ({
        current: { temperature: "—", feels: "—", humidity: "—", wind: 0,
                   condition: { icon: "🌤️", label: "—" }, time: "—" },
        days: [],
        today: { sunrise: "—", sunset: "—", moonrise: "—", moonset: "—",
                 moon: { icon: "🌙", label: "Phase unavailable", illumination: "" } },
        hourly: []
    })
    property string lastLocationKey: ""
    // Wall-clock timestamps survive a long suspend within the same Plasma session.
    // Use doubles: epoch milliseconds do not fit in a 32-bit QML int.
    property double lastAttemptMs: 0
    property double lastSuccessMs: 0
    property int generation: 0
    property var currentRequest: null
    // Every actual HTTP request (including a Moon-field fallback) gets its own timeout.
    signal requestStarted()

    function cancelDueToTimeout() {
        if (!busy) return;
        generation += 1;
        if (currentRequest) currentRequest.abort();
        currentRequest = null;
        busy = false;
        error = "Weather request timed out";
        console.warn("Glance Weather: " + error);
    }

    function refresh(latitude, longitude, temperatureUnit, windUnit) {
        if (!isFinite(latitude) || !isFinite(longitude) || latitude < -90 || latitude > 90
            || longitude < -180 || longitude > 180) return;
        generation += 1;
        var token = generation;
        if (currentRequest) {
            currentRequest.abort();
            currentRequest = null;
        }
        var locationKey = latitude + "," + longitude + "," + temperatureUnit + "," + windUnit;
        // Prevent weather for a previous city from appearing under the new city's name.
        if (locationKey !== lastLocationKey) hasData = false;
        busy = true;
        error = "";
        var common = [
            "latitude=" + encodeURIComponent(latitude),
            "longitude=" + encodeURIComponent(longitude),
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day",
            "hourly=temperature_2m,weather_code,precipitation_probability,is_day",
            "timezone=auto",
            "forecast_days=7",
            "temperature_unit=" + (temperatureUnit === "celsius" ? "celsius" : "fahrenheit"),
            "wind_speed_unit=" + (windUnit === "kmh" ? "kmh" : "mph")
        ];

        function beginRequest(includeMoon) {
            var daily = "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset";
            if (includeMoon) daily += ",moonrise,moonset,moon_phase";
            var params = common.concat(["daily=" + daily]);
            var request = new XMLHttpRequest();
            currentRequest = request;
            lastAttemptMs = Date.now();
            requestStarted(); // resets the timeout for this individual HTTP request
            request.onreadystatechange = function() {
                if (token !== generation || request.readyState !== XMLHttpRequest.DONE) return;
                if (request.status === 400 && includeMoon) {
                    // Compatibility with deployments that lack the newer moon fields.
                    beginRequest(false);
                    return;
                }
                currentRequest = null;
                busy = false;
                if (request.status !== 200) {
                    error = request.status === 0
                        ? "No HTTP response (check network or TLS)"
                        : "Could not fetch weather (HTTP " + request.status + ")";
                    console.warn("Glance Weather: " + error);
                    return;
                }
                try {
                    var payload = JSON.parse(request.responseText);
                    if (payload.error) throw new Error(payload.reason || "Weather API error");
                    var parsed = Weather.makeForecast(payload);
                    data = parsed;
                    lastLocationKey = locationKey;
                    hasData = true;
                    lastSuccessMs = Date.now();
                } catch (err) {
                    error = "Weather response error: " + err.message;
                    console.warn("Glance Weather: " + error);
                }
            };
            request.onerror = function() {
                if (token !== generation) return;
                currentRequest = null;
                busy = false;
                error = "Network error while fetching weather";
                console.warn("Glance Weather: " + error);
            };
            request.open("GET", "https://api.open-meteo.com/v1/forecast?" + params.join("&"));
            request.send();
        }
        beginRequest(true);
    }
}
