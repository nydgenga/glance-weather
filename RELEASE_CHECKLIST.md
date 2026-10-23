# Glance Weather 1.0.3 — Development checklist

**State:** 1.0.3-dev.4 is an unreleased development build. Public 1.0.2 remains stable.

## Completed automated checks

- [x] Existing parser, layout, stress, refresh and package checks
- [x] Partial hourly response regression tests (dev.1)
- [x] Location search request lifecycle tests (dev.2)
- [x] Error-aware API backoff tests, including recovery and reset cases (dev.3)
- [x] Deterministic archives, ZIP integrity, SHA-256 checksums
- [ ] GitHub Actions run on the latest dev.4 commit and artifact verified

## Desktop verification still required

- [ ] 1.0.3-dev.4 upgrades successfully without changing layout or settings
- [ ] Normal weather refresh and manual Refresh still work
- [ ] If practical, disconnect and restore the network to confirm fast recovery
- [ ] Rate limiting and 5xx backoff tested in automated request harness (no need to intentionally trigger live API errors)

- [x] User reports 1.0.3-dev.1 installed and displays normally
- [ ] 1.0.3-dev.4 installs/upgrades without losing location/units
- [x] City/postal-code search returns matching places and selection works
- [ ] No-result and offline searches end with a useful message; Search remains usable
- [ ] Two searches submitted in succession do not display outdated results
- [ ] Search timeout and cleanup remain functional if the service stalls
- [ ] Weather presentation, refresh and tooltips unchanged
- [ ] Nobara regression check if practical

## dev.4 packaging and logging checks

- [x] Source/plugin archives use an explicit file allowlist and reject missing required files
- [x] Regression test confirms stray local files do not enter release archives
- [x] Diagnostic tests distinguish repeated failures from new failure types
- [ ] dev.4 upgrade and weather behavior checked on Bazzite and/or Nobara

## Release policy

Do not publish or merge until the maintainer has tested and approved the intended changes. No accessibility features or additional settings have been added. Published version 1.0.2 remains unaffected.
