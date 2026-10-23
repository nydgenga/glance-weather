# Glance Weather 1.0.3 — Development checklist

**State:** 1.0.3-dev.2 is an unreleased development build. Public 1.0.2 remains stable.

## Completed automated checks

- [x] Existing parser, layout, stress, refresh and package checks
- [x] Partial hourly response regression tests (dev.1)
- [x] Location search request lifecycle tests (dev.2)
- [x] Deterministic archives, ZIP integrity, SHA-256 checksums
- [ ] GitHub Actions run on the latest dev.2 commit

## Desktop verification still required

- [x] User reports 1.0.3-dev.1 installed and displays normally
- [ ] 1.0.3-dev.2 installs/upgrades without losing location/units
- [ ] City/postal-code search returns matching places and selection works
- [ ] No-result and offline searches end with a useful message; Search remains usable
- [ ] Two searches submitted in succession do not display outdated results
- [ ] Search timeout and cleanup remain functional if the service stalls
- [ ] Weather presentation, refresh and tooltips unchanged
- [ ] Nobara regression check if practical

## Future development (not implemented in dev.2)

- Smarter API retry behavior for rate limits and server errors
- Packaging allowlist and small CI refinements
- Quieter error diagnostics

## Release policy

Do not publish or merge until the maintainer has tested and approved the intended changes. No accessibility features or additional settings have been added. Published version 1.0.2 remains unaffected.
