# Changelog

## [0.1.6] - 2026-03-31

### Added
- `update_social` accepts `human_observations:` kwarg; processes each observation into reputation signals (partner: 0.8 confidence, others: 0.5) and records communication reciprocity
- `SocialGraph#reputation_changes` array tracks dimension-level changes per update cycle; cleared at start of each `update_social` call
- `update_social` return hash includes `:reputation_updates` key with agent-level summary
- `update_theory_of_mind` accepts `human_observations:` kwarg; builds communication and channel-preference beliefs, infers engagement intent from direct-address observations, validates pending predictions
- `MentalStateTracker#pending_prediction(agent_id:)` returns most recent unvalidated prediction log entry
- Dirty tracking (`dirty?`, `mark_clean!`) on `SocialGraph` and `MentalStateTracker`
- Apollo Local persistence (`to_apollo_entries`, `from_apollo`, `mark_clean!`) on `SocialGraph` and `MentalStateTracker`; partner agents tagged with `'partner'` when `Legion::Gaia::BondRegistry` is present

## [0.1.5] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.4] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.3] - 2026-03-23

### Changed
- route llm calls through pipeline when available, add caller identity for attribution

## [0.1.2] - 2026-03-22

### Changed
- Add legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport as runtime dependencies
- Replace direct Legion::Logging calls with injected log helper in all runner modules
- Update spec_helper with real sub-gem helper stubs

## [0.1.1] - 2026-03-18

### Changed
- Enforce PRIORITY_TYPES validation in ShiftingEngine#add_perspective (returns error hash for invalid priorities)

## [0.1.0] - 2026-03-18

### Added
- Initial release as domain consolidation gem
- Consolidated source extensions into unified domain gem under `Legion::Extensions::Agentic::<Domain>`
- All sub-modules loaded from single entry point
- Full spec suite with zero failures
- RuboCop compliance across all files
