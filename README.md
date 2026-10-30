# lex-agentic-social

Domain consolidation gem for social cognition, governance, and multi-agent interaction. Bundles 17 sub-modules into one loadable unit under `Legion::Extensions::Agentic::Social`.

## Overview

**Gem**: `lex-agentic-social`
**Version**: 0.2.0
**Namespace**: `Legion::Extensions::Agentic::Social`

## Sub-Modules

| Sub-Module | Purpose |
|---|---|
| `Social::Social` | Group membership, multi-dimensional reputation, reciprocity, norm violations |
| `Social::TheoryOfMind` | BDI model — belief/desire/intention tracking, false-belief detection |
| `Social::Mentalizing` | Mentalizing network — tracking of mentalizing capacity |
| `Social::SocialLearning` | Learning by observation — vicarious reinforcement |
| `Social::PerspectiveShifting` | Deliberate perspective adoption |
| `Social::Trust` | Domain-scoped trust scores — asymmetric reinforcement and decay |
| `Social::Conflict` | Conflict registration, severity-based posture, optional LLM resolution |
| `Social::Conscience` | Internalized moral compass — guilt/pride signal generation |
| `Social::Consent` | Four-tier consent gradient with earned autonomy, HITL gate |
| `Social::MoralReasoning` | Six Haidt foundations, six Kohlberg stages, six ethical frameworks |
| `Social::Governance` | Four-layer governance — council proposals, quorum voting, action validation |
| `Social::JointAttention` | Shared attention between agents — coordinating focus |
| `Social::Mirror` | Mirror neuron analog — action observation, simulation, and resonance decay |
| `Social::MirrorSystem` | Extended mirror system with resonance-based familiarity tracking |
| `Social::Entrainment` | Rhythmic synchronization between agents |
| `Social::Symbiosis` | Mutually beneficial cognitive partnerships |
| `Social::Apprenticeship` | Expert-novice learning relationships |

## Actors

9 actors handle autonomous background processing:

- `Social::Conflict::Actors::StaleCheck` — every 3600s, checks for stale conflicts
- `Social::Consent::Actors::TierEvaluation` — every 3600s, evaluates and applies consent tiers
- `Social::Governance::Actors::ShadowAiScan` — interval actor, scans for shadow AI activity
- `Social::Governance::Actors::VoteTimeout` — every 300s, times out expired proposals
- `Social::JointAttention::Actors::Decay` — interval actor, decays joint attention focus
- `Social::Mentalizing::Actors::Decay` — interval actor, decays mentalizing model confidence
- `Social::Mirror::Actor::ResonanceDecay` — every 120s, decays resonance on observed actions
- `Social::MirrorSystem::Actors::Decay` — interval actor, decays mirror system activation
- `Social::Trust::Actors::Decay` — every 300s, decays all trust scores

## Safety Notes

`Social::Consent` governs whether actions require human approval — the HITL gate must not be bypassed. `Social::Governance` provides the council approval mechanism used by `Defense::Extinction` for containment escalation.

## Scoped calibration and trust

Pass a verified `identity:` when recording an advisory, or include it in the
existing `applied:` hash. Carry the same identity and available `exchange_id`
or `conversation_id` into the feedback observation. Multiple pending
advisories are matched by this attribution; ambiguous, mismatched, expired,
or repeated feedback cannot reinforce another response.

`Calibration::Client.new(calibration_registry: registry)` shares an explicitly
owned registry across clients. Without injection, clients remain independent.
Legacy unscoped receipts only accept unscoped feedback. GAIA must supply the
matching receipt attribution before identified feedback can be graded.
Receipt deduplication is process-local within the existing one-hour lifetime,
not durable exactly-once processing.

Trust runner methods accept `partner_identity:` independently of the worker's
`agent_id:`. Scoped trust is preserved through Apollo serialization and is
separate from legacy unscoped trust. Do not roll persisted scoped trust back
to readers that discard partner identity: they can merge separate people.
Calibration and trust do not grant consent or tool authority.

## Installation

```ruby
gem 'lex-agentic-social'
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
