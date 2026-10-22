# Changelog

## [1.0.2] — Maintenance and forecast tooltips (2026-10-22)

### Recovery and reliability (validated during 1.0.1 development)

- Refresh stale forecasts after suspension using wall-clock time, and retry failed network requests without waiting for the next half-hour refresh.
- Recover stalled in-flight requests after resume. Give each HTTP attempt, including the Moon-field compatibility fallback, an independent timeout.
- Preserve the prior successful forecast on temporary request failure, show useful error details on hover, and record concise errors in the Plasma user journal without logging location coordinates.
- Distinguish humidity and hourly precipitation probability using different symbols.
- Verified reconnection and sleep/wake recovery on both Bazzite and Nobara with the 1.0.1-rc.2 build.

### Tooltip improvements

- Label the header's Open-Meteo data timestamp as "As of"; hover to distinguish it from the actual successful download time.
- Show approximate daily warmest and coolest hours when hovering over any seven-day forecast column. Calculate these from already-retrieved hourly temperatures; daily high/low values are unchanged.
- No extra forecast API requests, additional fields, or faster polling.

**Release policy:** Versions 1.0.1-rc.1 and 1.0.1-rc.2 were development test builds only. No stable 1.0.1 release was published; its validated fixes are incorporated into 1.0.2.

Both the recovery changes and the tooltip refinements have been tested on Bazzite and Nobara with KDE Plasma 6.

## [1.0.0] — Initial public release

- Feature-complete design: current conditions, six-hour outlook, seven-day forecast, permanently visible humidity/wind and Sun/Moon information.
- Corrected lunar-phase interpolation to reflect Open-Meteo's **local-noon** sampling, including cycle wraparound and missing-data fallbacks.
- Confined narrow forecast-row symbols and unusually wide temperatures/probabilities to their own columns, without changing normal font sizes.
- Kept the weather symbol and prominent temperature separated using the rendered glyph width.
- Centered the Open-Meteo attribution and retained the visually tested 450 × 416 logical-pixel layout.
- New installs begin without a selected location; the search hint is a generic example.
- Added a release checklist, reproducible packaging script and a compact public README.
- No data migration is necessary from development versions; existing location/units remain in Plasma's local configuration.

## Pre-release development

The 0.1.x series iteratively established the layout, Open-Meteo integration, location configuration, lunar indicators, and display resilience. Development builds and their commit history are not part of the single-commit candidate being proposed for the main branch.
