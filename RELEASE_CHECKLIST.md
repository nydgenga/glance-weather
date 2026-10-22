# Glance Weather 1.0.2 — Combined maintenance release checklist

**State:** 1.0.2-rc.1 is a test candidate, not a published stable release. Public 1.0.0 is unchanged. No 1.0.1 release was published; the successful 1.0.1-rc.2 tests cover recovery behavior only, not the 1.0.2 tooltip additions.

## Automated checks

- [x] Existing weather, lunar-phase, stress, layout, release, and refresh tests
- [x] 1.0.2 tooltip / high-low hour coverage
- [x] No new API call or refresh-interval change for tooltips
- [x] Zero preset location, stable plugin ID, 0BSD license
- [x] Reproducible archives, ZIP integrity, SHA-256 checksums

## Proven manual results (during 1.0.1 development)

- [x] Bazzite: refresh after sleep and ordinary operation work
- [x] Nobara: reconnect after deliberate offline request without manual refresh
- [x] Nobara: resume from sleep triggers automatic recovery
- [x] 1.0.1-rc.2 tested on Bazzite and Nobara; user confirmed correct behavior

## Remaining Plasma 6 verification (new 1.0.2 behavior)

- [ ] Install 1.0.2-rc.1 over development version with `kpackagetool6 --upgrade`, then restart Plasma Shell.
- [ ] Confirm existing location, units, seven-day and six-hour layout, footer, glyph alignment and lack of unexpected scrollbar.
- [ ] Hover over the header's `As of` label. Verify both forecast-location data time and computer-local fetch date/time.
- [ ] After a successful refresh, verify `Last fetched` changes independently of the weather-data timestamp when applicable.
- [ ] Force a request failure; ensure the existing `Stale data` error is visible in the header hover tooltip.
- [ ] Hover each of seven day columns and verify approximate high/low hours, including across midnight; check near left/right panel edges.
- [ ] Confirm tooltips do not intercept clicks, freeze refreshing, overflow in a disruptive way, or add API requests.
- [ ] Recheck ordinary refresh and sleep/reconnect behavior on Bazzite and Nobara (regression verification).
- [ ] Maintainer approves stable 1.0.2 after testing.

## Publishing (only after signoff)

- [ ] Squash/merge the consolidated 1.0.2 PR into `main`, with no separate 1.0.1 merge.
- [ ] Bump metadata and tests from 1.0.2-rc.1 to 1.0.2, rebuild, verify archives/checksums.
- [ ] Tag the merged commit as 1.0.2, upload `.plasmoid`, source ZIP and checksum files, and publish official GitHub release.
- [ ] Retire completed development branches after merge, without assuming deleted refs erase historical commits.

## Implementation notes

The Qt QML timer is an event-loop watchdog, not an OS-level suspend or connectivity event listener. A one-minute wall-clock freshness check supports prompt recovery on resume; unsuccessful attempts normally retry about every two minutes. Hover-only forecast calculations reuse the existing Open-Meteo hourly temperatures and do not affect usage of its free API. The hourly warmest/coolest times are approximate and not identical to the maxima/minima times of the separately reported daily aggregates.
