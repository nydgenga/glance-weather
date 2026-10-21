# Changelog

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
