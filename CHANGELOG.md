# Changelog

## [1.0.1-rc.2] — Diagnostic recovery candidate

- Restart the 20-second HTTP timeout when a 400 response triggers the Moon-field compatibility fallback; slow second attempts are no longer timed against the original request.
- Preserve the actual failure cause in a hover tooltip for the **Stale data** label, and record concise errors in the Plasma Shell journal without location coordinates.
- Distinguish missing HTTP responses from ordinary HTTP error status codes.
- Document the initial Nobara recovery failure in rc.1 and successful Bazzite/Nobara reconnection and sleep/wake validation of rc.2.

## [1.0.1-rc.1] — First maintenance test candidate

- Recover forecast freshness after suspend/resume using wall-clock timestamps checked once a minute, rather than relying on an uninterrupted half-hour timer.
- Retry failed forecast requests every two minutes, so network restoration does not require a manual refresh or another full half-hour wait.
- Recover weather requests stuck in flight during sleep, while retaining the existing 20-second request timeout.
- Distinguish humidity (💧) from hourly precipitation probability (☔).
- Document the initial KDE Plasma 6 layout testing on Nobara alongside Bazzite.


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
