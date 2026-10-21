# Glance Weather

A compact, glanceable weather and astronomy plasmoid for KDE Plasma 6.

**Status:** experimental v0.1.7. Replaces the failed automatic-geometry approach with a fixed daily/hourly layout; awaiting visual validation on Bazzite.

## Features

- Current temperature, condition, feels-like, wind and humidity
- **Always-visible seven-day forecast**; no forecast-length preference
- Today's sunrise/sunset, moonrise/moonset, moon-phase emoji
- **Always-visible six-hour strip** between current conditions and the seven-day forecast; includes local time, weather emoji, temperature, and precipitation chance
- Colour Unicode emoji weather indicators, no bundled icon assets
- Search for a city or postal code in the settings
- Fahrenheit / Celsius and mph / km/h units
- Automatic refresh every 30 minutes, manual refresh, and stale-data indicator
- Native KDE colours and a compact desktop layout targeting ~450 × 416 px
- Larger supporting text for improved glanceability; moon phase labels distinguish principal events from waxing/waning intervals
- Humidity and wind are always displayed; the astronomy section remains optional
- Moon phase interpolation uses two consecutive forecast-day samples for a better time-of-day estimate

## Install on Bazzite or another Plasma 6 desktop

Download `glance-weather-0.1.7.plasmoid` from the accompanying artifacts. From a terminal, run:

```bash
kpackagetool6 --type Plasma/Applet --install ./glance-weather-0.1.7.plasmoid
```

Alternatively, if running from this source checkout:

```bash
kpackagetool6 --type Plasma/Applet --install ./package
```

Then right-click your desktop → **Add Widgets** → search for **Glance Weather** and add it. Right-click Glance Weather → **Configure Glance Weather**. Search for a city or postal code, click one of the matches, then **Apply** or **OK**. No default location is baked into the project.

The package ID is `com.github.nydgenga.glanceweather`; it can coexist with Advanced Weather Widget.

To update after later builds:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./glance-weather-0.1.7.plasmoid
```

To uninstall:

```bash
kpackagetool6 --type Plasma/Applet --remove com.github.nydgenga.glanceweather
```

Do not restart Plasma or remove its cache unless troubleshooting requires it.

## Provider / usage

Live data and location search: [Open-Meteo](https://open-meteo.com/). Attribution appears in the widget. The free API is intended for non-commercial use subject to the provider's terms and limits; commercial deployments need to check the provider's requirements.

Forecast API: `https://api.open-meteo.com/v1/forecast`

Location search: `https://geocoding-api.open-meteo.com/v1/search`

Sunrise, sunset, moonrise, moonset, and fractional lunar phase are returned by the forecast API. Lunar glyphs approximate one of eight phases; the weather model and astronomical data have different accuracy characteristics. Rise/set may be missing on some local dates, shown as `—`.

## Layout notes

The v0.1.7 design is a **fixed-content** compact display: current conditions and larger high/low temperatures, humidity and wind, six upcoming hours, seven forecast days, and Sun/Moon information. The target frame size is approximately **450 × 416 logical pixels**. The last astronomy section can still be hidden in settings, but the desktop frame's saved geometry will not automatically shrink. This is intentional: Plasma manages desktop widget geometry.

The hourly strip uses location-local forecast times and reports **precipitation probability**, not precipitation quantity. The horizontal strip assumes approximately 450px width for comfortable text; a scrollbar is retained for unusually undersized desktop widgets instead of truncating the entire footer.

**Existing desktop widgets may keep their saved 450 × 320 frame even after an upgrade.** Enter Plasma Edit Mode and resize the existing instance vertically to roughly 416px once. Updating the package won't guarantee geometry changes. Thereafter the content should fit without needing daily adjustments.

## Updating a running widget

After installing an updated package, Plasma may keep the old QML component in memory.
If the on-screen layout does not change after an upgrade, run:

```bash
systemctl --user restart plasma-plasmashell.service
```

Your desktop and panels will briefly reload. No system reboot is required.

## Known limitations

- **Visual confirmation pending:** source/static tests do not substitute for testing the 450 × 416 layout on a real KDE Plasma 6 desktop.
- Qt colour-emoji rendering depends on the installed emoji font.
- Moon phase glyphs remain one of eight approximations; event labels are short intervals, not exact phase event times. Midnight fractions are interpolated toward the next day when provided.
- Bazzite/Plasma may preserve an instance's old dimensions until it is resized in Edit Mode.
- Weather caches are in memory only; stale data survives a failed request but not a Plasma restart.
- If the Open-Meteo service lacks newer moon-phase fields, the widget falls back to the provider's basic weather and sunrise/sunset fields.

## Project and credits

Glance Weather was designed under the direction of its project maintainer with code-development assistance from OpenAI's ChatGPT. This statement does not assert that the maintainer personally authored every line of code.

Project-specific source code: **0BSD**. No code from Advanced Weather Widget was copied.

## Astronomical verification (v0.1.6)

The US Naval Observatory's 2026 primary-phase timetable gives New Moon (Oct 10 15:50 UTC), First Quarter (Oct 18 16:12 UTC), Full Moon (Oct 26 04:12 UTC), Last Quarter (Nov 1 20:28 UTC), and New Moon (Nov 9 07:02 UTC). We use these as independent sanity anchors for synthetic phase-cycle regression tests; they do not establish that the Open-Meteo live fractions are exact.

Source: https://aa.usno.navy.mil/calculated/moon/phases?year=2026
