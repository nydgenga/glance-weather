# Glance Weather 1.0.3 — Release checklist

**Candidate:** Stable 1.0.3. The public 1.0.2 package is the rollback baseline. The maintainers have authorized finalizing 1.0.3 after testing four unreleased development builds.

## Verified before publication

- [x] Plugin ID `com.github.nydgenga.glanceweather` and configuration keys unchanged; normal upgrades retain settings
- [x] All ten Node.js regression suites pass, including partial weather responses, geocoding lifecycle, HTTP backoff and archive-content checks
- [x] Pure JavaScript syntax checks pass; reproducible `.plasmoid` and source ZIP build succeeds; manifest and ZIP integrity check pass
- [x] Developer run of 1.0.3-dev.4 tested on **Bazzite** and **Nobara** by maintainer without apparent issues; normal location and weather behavior preserved
- [x] HTTP 429/5xx and callback failures validated with simulated responses, not forced against Open-Meteo production
- [x] Generic location placeholder, Open-Meteo attribution, 0BSD license and existing screenshot retained
- [x] No runtime UI or normal weather refresh change, no additional installed dependencies

## Publish through GitHub

- [ ] GitHub Actions checks complete successfully on the exact final 1.0.3 commit
- [ ] Squash-merge development PR #7 into `main` after the preceding check
- [ ] Create Git tag **`1.0.3`** on the merged commit (do not use a `v` prefix)
- [ ] Publish GitHub Release named **Glance Weather 1.0.3**, with release notes describing reliability and maintenance fixes
- [ ] Attach `glance-weather-1.0.3.plasmoid`, `glance-weather-1.0.3-source.zip`, and `glance-weather-1.0.3-sha256.txt`
- [ ] Verify public asset checksums against the final build

## Install and rollback

Upgrade: `kpackagetool6 --type Plasma/Applet --upgrade ./glance-weather-1.0.3.plasmoid`
Restart Plasma if its cached QML does not reload: `systemctl --user restart plasma-plasmashell.service`.
For rollback, use the preserved stable `1.0.2` `.plasmoid` with the same `--upgrade` command; there are no data-format migrations in 1.0.3.

The first published 1.0.3 package shares the tested development build's runtime code; changing the metadata version and release documentation does not itself provide additional desktop-test evidence.
