# lex-agentic-social

**Parent**: `../CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for social cognition, governance, and multi-agent interaction. Bundles 17 sub-modules into one loadable unit under `Legion::Extensions::Agentic::Social`.

**Gem**: `lex-agentic-social`
**Version**: 0.1.14
**Namespace**: `Legion::Extensions::Agentic::Social`

## Sub-Modules

| Sub-Module | Source Gem | Purpose | Runner Methods |
|---|---|---|---|
| `Social::Social` | `lex-social` | Group membership, multi-dimensional reputation, reciprocity, norm violations | `social_status`, `join_group`, `reputation_update` |
| `Social::TheoryOfMind` | `lex-theory-of-mind` | BDI model — belief/desire/intention tracking, false-belief detection | `theory_of_mind_status`, `update_belief` |
| `Social::Mentalizing` | `lex-mentalizing` | Mentalizing network — tracking of mentalizing capacity | `mentalizing_status`, `mentalize` |
| `Social::SocialLearning` | `lex-social-learning` | Learning by observation — vicarious reinforcement | `social_learning`, `social_learning_status` |
| `Social::PerspectiveShifting` | `lex-perspective-shifting` | Deliberate perspective adoption | `shift_perspective`, `perspective_shifting_status` |
| `Social::Trust` | `lex-trust` | Domain-scoped trust scores — asymmetric reinforcement and decay | `update_trust`, `get_trust`, `trust_status` |
| `Social::Conflict` | `lex-conflict` | Conflict registration, severity-based posture, optional LLM resolution | `register_conflict`, `resolve_conflict`, `conflict_status` |
| `Social::Conscience` | `lex-conscience` | Internalized moral compass — guilt/pride signal generation | `evaluate_conscience`, `conscience_status` |
| `Social::Consent` | `lex-consent` | Four-tier consent gradient with earned autonomy, HITL gate | `grant_consent`, `check_consent`, `consent_status` |
| `Social::MoralReasoning` | `lex-moral-reasoning` | Six Haidt foundations, six Kohlberg stages, six ethical frameworks | `moral_reasoning`, `moral_reasoning_status` |
| `Social::Governance` | `lex-governance` | Four-layer governance — council proposals, quorum voting, action validation | `create_proposal`, `vote_on_proposal`, `get_proposal`, `open_proposals`, `timeout_proposals`, `review_transition`, `validate_action` |
| `Social::JointAttention` | `lex-joint-attention` | Shared attention between agents — coordinating focus | `establish_joint_attention`, `joint_attention_status` |
| `Social::Mirror` | `lex-mirror` | Mirror neuron analog — action observation, simulation, and resonance | `observe_action`, `list_events`, `simulate`, `resonance`, `decay_resonances` |
| `Social::MirrorSystem` | `lex-mirror-system` | Extended mirror system with resonance-based familiarity tracking | `mirror`, `mirror_system_status` |
| `Social::Entrainment` | `lex-cognitive-entrainment` | Rhythmic synchronization between agents | `cognitive_entrainment`, `entrainment_status` |
| `Social::Symbiosis` | `lex-cognitive-symbiosis` | Mutually beneficial cognitive partnerships | `cognitive_symbiosis`, `symbiosis_status` |
| `Social::Apprenticeship` | `lex-cognitive-apprenticeship` | Expert-novice learning relationships | `cognitive_apprenticeship`, `apprenticeship_status` |

## Key Class: MirrorSystem::Helpers::ObservedBehavior

Tracks ongoing observations of a specific agent's behavior pattern keyed by `(agent_id, action, domain)`. Resonance increases with `observe_again` (repetition) or `boost_familiarity` (simulation), and decays over time. `faded?` returns true when resonance drops to floor.

**Distinct from** `SocialLearning::Helpers::ObservedBehavior`, which is a one-shot snapshot focused on whether the observer can reproduce a behavior (retention + reproduction flag). The MirrorSystem variant focuses on resonance-based familiarity and imitation fidelity over time.

## Actors

All actors extend `Legion::Extensions::Actors::Every` (interval-based).

| Actor | Interval | Target Method |
|---|---|---|
| `Social::Conflict::Actors::StaleCheck` | 3600s | checks for stale conflicts |
| `Social::Consent::Actors::TierEvaluation` | 3600s | evaluates and applies consent tier transitions |
| `Social::Governance::Actors::ShadowAiScan` | interval | scans for shadow AI activity |
| `Social::Governance::Actors::VoteTimeout` | 300s | times out expired proposals |
| `Social::JointAttention::Actors::Decay` | interval | decays joint attention focus |
| `Social::Mentalizing::Actors::Decay` | interval | decays mentalizing model confidence |
| `Social::Mirror::Actor::ResonanceDecay` | 120s | `Mirror::Client#decay_resonances` |
| `Social::MirrorSystem::Actors::Decay` | interval | decays mirror system activation |
| `Social::Trust::Actors::Decay` | 300s | decays all trust scores |

## Dependencies

| Gem | Purpose |
|---|---|
| `legion-cache` >= 1.3.11 | Cache access |
| `legion-crypt` >= 1.4.9 | Encryption/Vault |
| `legion-data` >= 1.4.17 | DB (Consent local migration `20260316000010_create_consent_domains`, Trust local migration `20260316000020_create_trust_entries`) |
| `legion-json` >= 1.2.1 | JSON serialization |
| `legion-logging` >= 1.3.2 | Logging |
| `legion-settings` >= 1.3.14 | Settings |
| `legion-transport` >= 1.3.9 | AMQP |

## Key Architecture Notes

- `Social::Governance` runner methods include `review_transition(action:, authority:, context:)` which delegates to `validate_action` at the `:agent_validation` layer, and `validate_action(layer:, action:, _context:)` which enforces governance layer rules.
- `Social::Governance#validate_action` accepts layers: `:agent_validation`, `:anomaly_detection`, `:human_deliberation`, `:transparency`. The `:human_deliberation` layer always returns `allowed: false` (HITL gate).
- `Social::Mirror` has three runner modules: `Observe`, `Simulate`, `Resonance`. All share a single `mirror_engine` instance via the `Client` class.

## Safety-Critical Notes

- `Social::Consent` governs whether actions require human approval. The HITL gate for autonomous promotion must not be bypassed.
- `Social::Governance` provides the council approval mechanism used by `Defense::Extinction` for containment escalation.

## Development

```bash
bundle install
bundle exec rspec        # 0 failures
bundle exec rubocop      # 0 offenses
```
