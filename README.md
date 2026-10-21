# Glance Weather

A compact, glanceable weather and astronomy plasmoid for KDE Plasma 6.

**Status:** early prototype v0.1.4; the v0.1.3 layout was tested on Bazzite, with small spacing refinements awaiting confirmation.

## Features

- Current temperature, condition, feels-like, wind and humidity
- 3–7 day **always-visible** forecast (5 days by default)
- Today's sunrise/sunset, moonrise/moonset, moon-phase emoji
- Pop-up showing the next six hourly forecast entries
- Colour Unicode emoji weather indicators, no bundled icon assets
- Search for a city or postal code in the settings
- Fahrenheit / Celsius and mph / km/h units
- Automatic refresh every 30 minutes, manual refresh, and stale-data indicator
- Native KDE colours and a compact desktop layout (~450 × 320 px)

## Install on Bazzite or another Plasma 6 desktop

Download `glance-weather-0.1.4.plasmoid` from the accompanying artifacts. From a terminal, run:

```bash
kpackagetool6 --type Plasma/Applet --install ./glance-weather-0.1.4.plasmoid
```

Alternatively, if running from this source checkout:

```bash
kpackagetool6 --type Plasma/Applet --install ./package
```

Then right-click your desktop → **Add Widgets** → search for **Glance Weather** and add it. Right-click Glance Weather → **Configure Glance Weather**. Search for a city or postal code, click one of the matches, then **Apply** or **OK**. No default location is baked into the project.

The package ID is `com.github.nydgenga.glanceweather`; it can coexist with Advanced Weather Widget.

To update after later builds:

```bash
kpackagetool6 --type Plasma/Applet --upgrade ./glance-weather-0.1.4.plasmoid
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

The default 450 × 320 layout reserves an 85px forecast area, giving the day-low temperatures about 12px additional breathing room before the Sun/Moon divider. The nominal content height is ~305px including its own padding, so it should fit the default panel without a scrollbar. Exceptionally small sizes retain the scroll fallback.

## Updating a running widget

After installing an updated package, Plasma may keep the old QML component in memory.
If the on-screen layout does not change after an upgrade, run:

```bash
systemctl --user restart plasma-plasmashell.service
```

Your desktop and panels will briefly reload. No system reboot is required.

## Known limitations

- **Ongoing desktop testing is essential.** v0.1.0 successfully loaded and fetched weather on Bazzite. v0.1.3 removed the scrollbar; v0.1.4 reallocates 12px of spare space to the gap below the forecast, pending on-device confirmation.
- Qt colour-emoji rendering depends on the available system emoji font.
- Hourly forecast is deliberately a small on-demand popup, not a permanently visible section.
- The moon-phase icon is one of eight Unicode approximations, not an exact rendering of the illuminated disc.
- Caching is in memory only; stale data survives a failed refresh but not a Plasma restart.
- Astronomy comes from Open-Meteo's recently added daily fields; API availability should be verified on the user's Bazzite system.

## Project and credits

Glance Weather was designed under the direction of its project maintainer with code-development assistance from OpenAI's ChatGPT. This statement does not assert that the maintainer personally authored every line of code.

Project-specific source code: **0BSD**. No code from Advanced Weather Widget was copied.
