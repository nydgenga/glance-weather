# Glance Weather 1.0 — Release checklist

**State:** Release candidate prepared; no 1.0.0 tag, GitHub release or store listing has been published.

## Automated validation

- [x] Node weather-parsing tests
- [x] Synthetic lunar interpolation and phase-boundary tests
- [x] All recognized weather-code icons (day/night) and extreme-value stress fixtures
- [x] Static QML layout and configuration tests
- [x] Package content and version/license checks
- [x] No hardcoded default city, postal code or user screenshot in the release package
- [x] Reproducible `.plasmoid` and source archive generation

## Manual validation on KDE Plasma 6

- [ ] Upgrade the current widget with the 1.0.0-rc.1 `.plasmoid`, reload Plasma Shell and verify the existing location and unit settings are retained.
- [ ] Check the current temperature, six-hour row, seven-day row, Sun/Moon area, and centered footer for overlaps or unwanted scrollbars.
- [ ] Change temperature units to Celsius and wind units to km/h; confirm displayed values update.
- [ ] Search for a **neutral public demo city** and confirm that the widget title, times and forecasts update.
- [ ] Optionally try a different emoji font or high DPI setting, if available.
- [ ] Verify a brand-new instance with no saved location asks for a location rather than showing a previously used one.
- [ ] Record any errors and final sign-off.

## Privacy and publication decisions

- [ ] Review the previous public draft PR and branch for historical location examples. The clean release branch starts from `main`, not from the development branch, but **old refs and cached copies can remain accessible** until addressed.
- [ ] Explicitly decide what to do with the old draft PR / development branch and whether stronger Git-history remediation is warranted. Never assume deleting a branch erases all prior exposure.
- [ ] If publishing screenshots, set a neutral city before capturing them and inspect all desktop corners for personal information.
- [ ] Approve the release candidate, merge the clean release PR, change metadata/README from `1.0.0-rc.1` to `1.0.0`, then create a version tag and GitHub release with the installable package and checksum.
- [ ] Only after publication, optionally consider KDE Store distribution.

## External services

Forecasts and geocoding rely on Open-Meteo. The widget displays attribution and uses the hosted **free API for noncommercial use**; public documentation also notes CC BY 4.0 weather data terms. Check the provider's current terms before changing distribution or monetization.
