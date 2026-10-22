# Glance Weather 1.0.2 — Release verification

**Release decision:** Maintainer approved shipping 1.0.2 after testing the tooltips on Bazzite and Nobara. Stable 1.0.1 was intentionally skipped; both 1.0.1 development candidates remain unreleased.

## Confirmed automated verification

- [x] Weather, lunar-phase, stress, layout, release, refresh, and timestamp test suites pass
- [x] No additional HTTP requests or higher forecast refresh frequency for tooltips
- [x] Plugin ID is unchanged; new installations ship without a preset city or coordinates
- [x] 0BSD software license, Open-Meteo attribution, and example screenshot checked
- [x] Reproducible `.plasmoid` and source archives and SHA-256 manifest verified

## Manual tests reported by maintainer

- [x] Bazzite: widget layout and forecast operation
- [x] Nobara: widget layout and forecast operation
- [x] Automatic recovery after sleep on Bazzite and Nobara, using 1.0.1-rc.2
- [x] Network-disconnection and automatic reconnection test on Nobara, using 1.0.1-rc.2
- [x] Weather-data/fetch-time tooltip in 1.0.2 candidate
- [x] Seven-day high/low-hour tooltip in 1.0.2 candidate
- [x] Simplified tooltip text accepted and tested on Bazzite and Nobara

Tests reported as successful do not imply every edge case or device was tested.

## GitHub publication

- [ ] Squash-merge the finalized 1.0.2 changes from PR #4 into `main`
- [ ] Create the **1.0.2** tag on the merged `main` commit (no `v` prefix)
- [ ] Publish a GitHub Release named **Glance Weather 1.0.2**
- [ ] Attach `glance-weather-1.0.2.plasmoid`, `glance-weather-1.0.2-source.zip`, and `glance-weather-1.0.2-sha256.txt`
- [ ] Verify published downloads and checksums

The source, binaries, and hashes must match the same finalized commit. If the publication is done outside this workspace, check these items after publishing.

## Implementation notes

A one-minute wall-clock watchdog checks for overdue refreshes after resume, while unsuccessful forecast attempts normally retry approximately every two minutes. Hover-only forecast calculations reuse existing Open-Meteo hourly temperatures. The warmest/coolest hours are estimates rather than exact extrema times of the separate daily aggregates.
