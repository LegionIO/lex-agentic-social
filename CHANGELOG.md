# Changelog

## [0.1.15] - 2026-04-27
### Fixed
- Stop social calibration partner-knowledge promotion when Legion is shutting down or Apollo Local becomes unavailable between promotable tag groups

## [0.1.14] - 2026-04-22
### Added
- `Governance#review_transition` method — API expected by lex-extinction for containment governance gate
- Mirror::Actor::ResonanceDecay (120s) for `decay_resonances`
### Fixed
- `Governance#validate_action` now logs the action parameter instead of ignoring it
- Documented Mirror vs MirrorSystem state isolation and ObservedBehavior class distinctions

## [0.1.13] - 2026-04-15
### Changed
- Set `mcp_tools?`, `mcp_tools_deferred?`, and `transport_required?` to `false` — internal cognitive pipeline extension

## [0.1.12] - 2026-04-03
### Fixed
- fix TheoryOfMind phase key from social to social_cognition to match GAIA phase map

## [0.1.11] - 2026-04-03

### Fixed
- `retrieve_from_apollo_local` now correctly unpacks `{ success:, results: }` hash from `Apollo::Local.query_by_tags` instead of treating it as an array

## [0.1.10] - 2026-03-31

### Fixed
- `extract_style_signals`: replace hardcoded `frequency_variance: 0.0` and `reciprocity_imbalance: 0.0` with real computations (`compute_frequency_variance` from hourly bucket counts, `compute_reciprocity_imbalance` from agent/human direction ratio); `:anxious` attachment style is now reachable
- `reflect_on_bonds`: `narrative:` field now returns a mechanically generated sentence (stage, style, health, chapter, milestones) instead of always nil
- `reflect_on_bonds`: add `absence_exceeds_pattern:` field backed by `Legion::Extensions::Agentic::Memory::CommunicationPattern` when available, falling back to Apollo Local communication pattern data
- `retrieve_interaction_traces` in calibration: split into `retrieve_from_memory` + `retrieve_from_apollo_local` fallback; now returns data from Apollo Local when lex-agentic-memory is absent
- `check_airb_compliance` in shadow_ai: return `reason:` field alongside `source: :unavailable` so callers know why the check could not run; emit debug log entry

## [0.1.9] - 2026-03-31

### Added
- Calibration sub-module: CalibrationStore with EMA tracking, explicit feedback detection, partner baseline tracking
- CalibrationRunner: update_calibration, record_advisory_meta, detect_explicit_feedback, calibration_weights, calibration_stats
- sync_partner_knowledge: LLM preference extraction (weekly) + partner knowledge promotion to Apollo Global
- Apollo Local persistence via dirty?/to_apollo_entries/from_apollo pattern

## [0.1.8] - 2026-03-31

### Added
- Attachment sub-module for Phase C bond modeling
- `AttachmentModel`: per-agent attachment strength, style, and stage tracking with EMA updates and no-regression stage transitions
- `AttachmentStore`: in-memory store with dirty tracking and Apollo Local persistence (`to_apollo_entries`, `from_apollo`)
- `Attachment` runner: `update_attachment` (tick integration), `reflect_on_bonds` (dream cycle orchestrator reading cross-module bond data), `attachment_stats`

## [0.1.7] - 2026-03-31

### Changed
- Migrate `TrustMap` persistence from Data::Local SQLite to Apollo Local (`to_apollo_entries`, `from_apollo`)
- Add dirty tracking (`dirty?`, `mark_clean!`) to `TrustMap` matching SocialGraph/MentalStateTracker pattern
- Tag schema: `['trust', 'trust_entry', '<agent_id>', '<domain>']` with optional `'partner'` tag via BondRegistry
- Remove Data::Local migration registration from trust entry point (migration file retained for existing installs)
- Add one-time `scripts/migrate_trust_to_apollo.rb` for legacy SQLite data migration

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
