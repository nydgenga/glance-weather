# Glance Weather

A compact, glanceable weather and astronomy plasmoid for KDE Plasma 6.

**Status:** experimental v0.1.11. Centers attribution and permanently shows the Sun/Moon section, with no visual changes elsewhere. Awaiting confirmation on Bazzite.

## Features

- Prominent current temperature and condition on the left; high/low, feels-like, humidity and wind grouped on the right
- **Always-visible seven-day forecast**; no forecast-length preference
- Today's sunrise/sunset, moonrise/moonset, moon-phase emoji
- **Always-visible six-hour strip** between current conditions and the seven-day forecast, with more spacing between time, weather symbol, temperature and precipitation chance
- Colour Unicode emoji weather indicators, no bundled icon assets
- Search for a city or postal code in the settings
- Fahrenheit / Celsius and mph / km/h units
- Automatic refresh every 30 minutes, manual refresh, and stale-data indicator
- Native KDE colours and a compact desktop layout targeting ~450 × 416 px
- Larger supporting text for improved glanceability; moon phase labels distinguish principal events from waxing/waning intervals
- Humidity, wind, and astronomy are always displayed
- Moon phase interpolation uses two consecutive forecast-day samples for a better time-of-day estimate

## Install on Bazzite or another Plasma 6 desktop

Download `glance-weather-0.1.11.plasmoid` from the accompanying artifacts. From a terminal, run:

```bash
kpackagetool6 --type Plasma/Applet --install ./glance-weather-0.1.11.plasmoid
```

Alternatively, if running from this source checkout:

```bash
kpackagetool6 --type Plasma/Applet --install ./package
```

Then right-click your desktop → **Add Widgets** → search for **Glance Weather** and add it. Right-click Glance Weather → **Configure Glance Weather**. Search for a city or postal code, click one of the matches, then **Apply** or **OK**. No default location is baked into the project.

The package ID is `com.github.nydgenga.glanceweather`; it can coexist with Advanced Weather Widget.

To update after later builds:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./glance-weather-0.1.11.plasmoid
```

To uninstall:

```bash
kpackagetool6 --type Plasma/Applet --remove com.github.nydgenga.glanceweather
```

Restart Plasma Shell after updating an already-running widget to ensure the revised QML loads. Do not delete user settings or caches unless troubleshooting requires it.

## Provider / usage

Live data and location search: [Open-Meteo](https://open-meteo.com/). Attribution appears in the widget. The free API is intended for non-commercial use subject to the provider's terms and limits; commercial deployments need to check the provider's requirements.

Forecast API: `https://api.open-meteo.com/v1/forecast`

Location search: `https://geocoding-api.open-meteo.com/v1/search`

Sunrise, sunset, moonrise, moonset, and fractional lunar phase are returned by the forecast API. Lunar glyphs approximate one of eight phases; the weather model and astronomical data have different accuracy characteristics. Rise/set may be missing on some local dates, shown as `—`.

## Layout notes

The v0.1.9 design is a **fixed-content** compact display: a taller current-conditions block on the left; high/low, feels-like, humidity and wind aligned on the right; six upcoming hours with more vertical breathing room; seven forecast days; and Sun/Moon information. The target frame size is approximately **450 × 416 logical pixels**. Astronomy is always visible; there is no longer a setting to hide it. Plasma manages the desktop widget geometry, so removing this option also avoids an empty fixed-height frame.

The taller hourly strip uses location-local forecast times and reports **precipitation probability**, not precipitation quantity. The horizontal strip assumes approximately 450px width for comfortable text; a scrollbar is retained for unusually undersized desktop widgets instead of truncating the entire footer.

**Existing desktop widgets can keep their previously saved size after an upgrade.** This version aims to fit the content in a roughly 450 × 416 frame. If an older instance is shorter than that, extend it to about 416 logical pixels in Plasma Edit Mode. If it is already large enough, no manual resize should be necessary.

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

## Version 0.1.9 scrollbar correction

Bazzite confirmed the larger v0.1.8 current-temperature and hourly layouts, but the 450×444 logical-pixel declared frame still showed an unwanted scrollbar on an existing desktop instance. This revision **preserves the typography, exact six-hour label/icon/temperature/rain positioning, the seven-day forecast height, and the right-aligned current metrics**, while reducing excess container allocations, section spacing, and top/bottom reserved padding. The static content-height budget is now **399 logical pixels**, leaving 17 pixels in the intended 450×416 frame. The viewport uses its actual QML top inset when computing content height. Plasma's saved instance geometry still takes precedence over default height declarations; very small manually resized widgets retain a scroll fallback. The correction requires on-device visual confirmation.

## Version 0.1.10 spacing refinements

- **Variable-width weather emojis:** The temperature and description are positioned relative to the weather emoji's rendered `implicitWidth`, plus an 11-pixel gap at normal widths (7 pixels on narrow layouts). This avoids collisions when emoji glyphs vary in width.
- **Unused lower space:** Rather than stretching the widget or making the text smaller, the existing section gaps expand from 2 to at most 9 logical pixels when a desktop widget has extra height. The space is distributed between sections, including near the footer, rather than accumulating below the attribution. No new settings.
- **Plasma geometry:** A saved desktop widget retains its previous outer dimensions. This revision fills those dimensions more evenly; it does not attempt to change Plasma's saved geometry.

As before, the package requires testing in a real Plasma 6 session. The QML's height-dependent spacing is covered by static checks and budget tests for 416px and 444px viewports, but exact emoji width and font metrics can only be confirmed in KDE.

## Version 0.1.11 footer and settings refinement

- The **Weather by Open-Meteo** attribution is horizontally centered within the full-width widget content area, rather than aligned to the left. Its text size, colour and footer height are unchanged.
- The Sun/Moon section is permanently visible. Removed the **Show sun and moon** checkbox, its QML configuration property, and its KConfig entry. Existing saved `showAstronomy=false` preferences are no longer read, so upgrading restores the astronomy section even if it was previously disabled.
- The 450 × 416 default size, spacing budget, hourly and seven-day forecasts, font sizes, and units remain unchanged.

In an already-running Plasma session, restart Plasma Shell after upgrading to load the new QML.
