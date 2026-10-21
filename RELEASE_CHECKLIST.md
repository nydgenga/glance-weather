# Glance Weather 1.0 — Release checklist

**State:** Glance Weather 1.0.0 approved for release following successful Bazzite visual testing. GitHub tag/release publication is tracked separately.

## Automated validation

- [x] Node weather-parsing tests
- [x] Synthetic lunar interpolation and phase-boundary tests
- [x] All recognized weather-code icons (day/night) and extreme-value stress fixtures
- [x] Static QML layout and configuration tests
- [x] Package content and version/license checks
- [x] No hardcoded default city, postal code or user screenshot in the release package
- [x] Reproducible `.plasmoid` and source archive generation

## Manual validation on KDE Plasma 6

- [x] Installed the 1.0.0-rc.1 candidate on Bazzite; original weather location remained in place and the layout rendered successfully.
- [x] Confirmed current temperature, six-hour row, seven-day row, Sun/Moon area, and centered footer render without overlaps or unwanted scrollbars (user screenshot).
- [ ] Change temperature units to Celsius and wind units to km/h; confirm displayed values update.
- [ ] Search for a **neutral public demo city** and confirm that the widget title, times and forecasts update.
- [ ] Optionally try a different emoji font or high DPI setting, if available.
- [ ] Verify a brand-new instance with no saved location asks for a location rather than showing a previously used one.
- [x] Project maintainer approved proceeding with the first stable release.

## Privacy and publication decisions

- [x] Identified the previous public draft PR and branch as historical sources containing an old location example. The clean release branch starts from `main` and does not inherit that history. **Old refs and cached copies may remain accessible**.
- [ ] Close development PR #1 and, if desired, manually delete its branch `prototype/v0.1.1` after ensuring no more development changes are needed. Old GitHub caches and links may still expose past commits.
- [ ] If publishing screenshots, set a neutral city before capturing them and inspect all desktop corners for personal information.
- [ ] Merge approved clean release PR #2, then create Git tag `v1.0.0` and publish a GitHub release with the installable package, source archive, and checksums.
- [ ] Only after publication, optionally consider KDE Store distribution.

## External services

Forecasts and geocoding rely on Open-Meteo. The widget displays attribution and uses the hosted **free API for noncommercial use**; public documentation also notes CC BY 4.0 weather data terms. Check the provider's current terms before changing distribution or monetization.
