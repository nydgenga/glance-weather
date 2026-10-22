# Glance Weather 1.0.1 — Maintenance release checklist

**State:** 1.0.1-rc.2 is an unverified follow-up candidate: the 1.0.1-rc.1 recovery test passed on Bazzite but failed with a stale-data status on Nobara. Version 1.0.0 remains the published stable release until the maintainer tests and approves these changes.

## Automated validation

- [x] Existing weather parsing, lunar interpolation, icon stress, and layout tests
- [x] New sleep, retry, system-clock-adjustment and stalled-request scheduling tests
- [x] Distinct humidity and precipitation glyphs checked in QML
- [x] No preset city or private location in configuration defaults
- [x] Reproducible ZIP and plasmoid archives, correct package version and 0BSD license

## Manual Plasma 6 checks (1.0.1-rc.2 still awaiting validation)

- [ ] Install over 1.0.0 and restart Plasma Shell; verify saved location and units remain intact.
- [ ] Confirm the hourly six-hour row uses ☔ for precipitation and the current humidity uses 💧; check for glyph clipping and accidental new scrollbars.
- [ ] While online, click Refresh and confirm the weather loads normally.
- [ ] Disconnect the computer from the Internet, click Refresh to produce a failure, reconnect, and verify recovery without pressing Refresh again. Allow roughly 2–3 minutes for a retry plus request time.
- [ ] If practical, suspend the computer for longer than 30 minutes, resume with networking available, and confirm the forecast updates without a manual refresh (normally within about a minute plus request time).
- [ ] If a request was pending when suspension occurred, verify the widget does not stay indefinitely stuck on “Updating…”.
- [x] 1.0.1-rc.1: Initial Bazzite post-suspend recovery worked.
- [ ] 1.0.1-rc.2: Retest on Nobara; if "Stale data" appears, hover the label for the exact network error. Allow a two-minute retry window before judging whether recovery failed.
- [ ] 1.0.1-rc.2: Confirm Bazzite remains unaffected.
- [ ] Maintainer approves 1.0.1 for merge and release.

## Publishing

- [x] Glance Weather 1.0.0 published from the clean `main` branch; superseded development PR closed and branch removed.
- [ ] Keep 1.0.1 as a separate PR until runtime checks are complete; do not change `main` prematurely.
- [ ] Replace 1.0.1-rc.2 metadata and filenames with 1.0.1 after approval; rerun tests and package.
- [ ] Merge the approved change, tag the resulting commit, and publish a GitHub release with the `.plasmoid`, source ZIP and SHA-256 checksums.

## Notes

QML Timer runs in the Plasma animation/event loop, so the one-minute watchdog is a **best-effort wake check**, not an OS-level network-connectivity or suspend event listener. The recovery logic relies on wall-clock timestamps and retries even if the prior request failed while offline. The fallback request now resets its own timeout and logs errors without printing selected coordinates. Forecast and geocoding services remain Open-Meteo; free hosted API restrictions still apply.
