# lex-agentic-social

Domain consolidation gem for social cognition, governance, and multi-agent interaction. Bundles 17 sub-modules into one loadable unit under `Legion::Extensions::Agentic::Social`.

## Key Sub-Modules

| Sub-Module | Purpose |
|---|---|
| `Social::Social` | Group membership, multi-dimensional reputation, reciprocity, norm violations |
| `Social::TheoryOfMind` | BDI model — belief/desire/intention tracking, false-belief detection |
| `Social::Trust` | Domain-scoped trust scores — asymmetric reinforcement and decay |
| `Social::Conflict` | Conflict registration, severity-based posture, optional LLM resolution |
| `Social::Consent` | Four-tier consent gradient with earned autonomy, HITL gate |
| `Social::MoralReasoning` | Six Haidt foundations, six Kohlberg stages, six ethical frameworks |
| `Social::Governance` | Four-layer governance — council proposals, quorum voting, action validation |
| `Social::Mirror` | Mirror neuron analog — action observation, simulation, and resonance |

## Key Architecture Notes

- `Social::Governance#validate_action` accepts layers: `:agent_validation`, `:anomaly_detection`, `:human_deliberation`, `:transparency`. The `:human_deliberation` layer always returns `allowed: false` (HITL gate).
- `Social::Mirror` has three runner modules: `Observe`, `Simulate`, `Resonance`. All share a single `mirror_engine` instance via the `Client` class.
- `MirrorSystem::Helpers::ObservedBehavior` tracks ongoing observations keyed by `(agent_id, action, domain)` with resonance decay. **Distinct from** `SocialLearning::Helpers::ObservedBehavior` which is a one-shot snapshot.

## Safety-Critical Notes

- `Social::Consent` governs whether actions require human approval. The HITL gate for autonomous promotion must not be bypassed.
- `Social::Governance` provides the council approval mechanism used by `Defense::Extinction` for containment escalation.

## Local DB Migrations

- `20260316000010_create_consent_domains` (Consent)
- `20260316000020_create_trust_entries` (Trust)
