# Glance Weather

A compact desktop weather and astronomy widget for **KDE Plasma 6**, designed to show what matters without opening extra panels.

![Glance Weather showing the current weather, six-hour outlook, seven-day forecast, and Sun/Moon times for Dallas, Texas](screenshots/glance-weather.png)

**Published stable version:** 1.0.2 (tested on Bazzite and Nobara with KDE Plasma 6). **This branch:** 1.0.3-dev.4, an unreleased reliability test build. The first three improvements were tested on Bazzite and Nobara; the dev.4 packaging and logging adjustments still need desktop verification.

## Features

- Current weather, including temperature, feels-like temperature, humidity, wind, and today's high/low
- Six-hour outlook with conditions, temperatures, and precipitation probabilities
- Seven-day forecast with daily high and low temperatures
- Sunrise, sunset, moonrise, moonset, and Moon-phase information
- Automatic weather updates and manual refresh
- Search by city or postal code, with configurable temperature and wind units
- Compact KDE Plasma 6 desktop layout

## New in 1.0.2

- Hover over the weather data timestamp to see when the forecast was last successfully fetched.
- Hover over a day in the seven-day outlook to see the approximate times of its warmest and coolest forecast hours.

Both tooltips use existing forecast data without additional API requests or more frequent refreshes.

## Under development for 1.0.3

- Preserve valid current and seven-day forecasts if optional hourly API data is incomplete. Unavailable hours show placeholders rather than invalidating the entire response.
- Time out stalled location searches after 15 seconds, cleanly abort cancelled searches, and ignore outdated responses.
- Back off repeated HTTP 429 rate-limit and 5xx provider failures (up to 30 minutes); keep rapid network-recovery retries, manual refresh, and the 30-minute normal refresh schedule.
- Whitelist the release package and source archive contents so unrelated local files cannot accidentally ship.
- Suppress duplicate network callbacks and excessive identical journal warnings during extended outages while retaining the current error in the widget.
- Run automated regression checks in GitHub Actions and attach the resulting packages for development testing. These changes do not alter forecast API usage.

## Requirements

- KDE Plasma **6** (the package is not intended for Plasma 5)
- Working internet connection for forecast and place searches
- An emoji-capable font (appearance depends on the operating system)

Tested on **Bazzite** and **Nobara** Linux. The recovery fixes passed suspend/resume and network-reconnection tests; the two new tooltips and their simplified wording were tested on both distributions. Other Plasma 6 configurations may render symbols or scaling differently.

## Install and upgrade

For the 1.0.3 development candidate, download `glance-weather-1.0.3-dev.4.plasmoid`, open a terminal in the download directory, and run:

```bash
kpackagetool6 --type Plasma/Applet --install ./glance-weather-1.0.3-dev.4.plasmoid
```

To upgrade an existing Glance Weather installation, keeping saved settings:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./glance-weather-1.0.3-dev.4.plasmoid
systemctl --user restart plasma-plasmashell.service
```

The Plasma Shell restart refreshes already-loaded QML and briefly reloads panels. There is no need to restart the entire computer.

Right-click the desktop, choose **Add Widgets**, add **Glance Weather**, then open its configuration to select a location. The widget ships **without a preset city or coordinates**. The location search field's example is Seattle/98101; it is not an automatic selection.

To remove the widget entirely:

```bash
kpackagetool6 --type Plasma/Applet --remove com.github.nydgenga.glanceweather
```

To install directly from a source checkout:

```bash
kpackagetool6 --type Plasma/Applet --install ./package
```

## Privacy and network use

Glance Weather has no accounts, analytics or advertising code. Forecast requests send the selected coordinates to `https://api.open-meteo.com/v1/forecast`, and city/postal searches send search terms to `https://geocoding-api.open-meteo.com/v1/search`. The selected place and units are saved locally by Plasma; upgrading does not reset them. Check your chosen city before taking a public screenshot.

No hardcoded home city or ZIP is included as a default, and the release package contains no user screenshots. As with any network service, Open-Meteo can receive request metadata such as IP address.

## Data sources and attribution

Weather, astronomical data and place search are supplied by [Open-Meteo](https://open-meteo.com/), credited in the widget's footer. Open-Meteo weather data uses [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) attribution terms; the provider's free hosted API is limited to **noncommercial use** under its [current terms](https://open-meteo.com/en/terms). Commercial integrators should arrange an appropriate data service rather than assuming the free endpoint may be used commercially.

Moon phases are derived from Open-Meteo's daily numerical phase observations sampled at local **noon**. The widget estimates a current phase from consecutive noon samples, using a limited backward extrapolation before noon. The eight named phases are approximate intervals, **not exact astronomical event times**. The Moon may have no rise or set time on some local dates, shown as `—`.

## Limitations

- Plasma may retain an old desktop widget's saved size after a package update. The intended size is around 450 × 416 logical pixels; manually resize in Edit Mode when necessary.
- When deliberately resized much smaller, the content may scroll rather than become unreadably small.
- Forecasts require network access. A one-minute watchdog detects overdue refreshes after sleep. Network failures retry approximately every two minutes (plus up to one minute for the next check), while HTTP 429 rate limits and 5xx server failures use progressively longer delays capped at 30 minutes. Manual Refresh remains available. If a retained forecast shows **Stale data**, hover over that label to read the actual request error; the Plasma user journal also records messages prefixed `Glance Weather:`. The in-memory last successful forecast can remain visible after a temporary request failure, but is lost after Plasma restarts.
- Appearance of Unicode emoji depends on installed fonts, theme and scaling; unusual values fit or clip rather than overlap adjacent forecasts.
- A location's local time is used for forecast hours and astronomical times, which can differ from the computer's timezone.
- Automated parser, layout-structure, numeric-stress and package checks supplement real-world KDE Plasma testing.

## Development

Pure JavaScript parsing and QML UI; no binary dependencies beyond the normal Plasma runtime. From the repository root:

```bash
node tests/test-weather.js
node tests/test-stress.js
node tests/test-layout.js
node tests/test-release.js
node tests/test-refresh.js
node tests/test-timestamps.js
python3 scripts/package.py
```

The packaging script builds deterministic allowlisted `.plasmoid` and source `.zip` archives in `dist/`; new release files must be explicitly registered in `scripts/package.py`. See [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for release verification and [CHANGELOG.md](CHANGELOG.md) for release history.

## License and credits

Glance Weather source is released under the [Zero-Clause BSD license (0BSD)](LICENSE). The Open-Meteo weather data is separately licensed and attributed as noted above.

The widget was designed under the direction of its project maintainer, with code-development assistance from OpenAI's ChatGPT. This does not imply the maintainer personally authored every line.
