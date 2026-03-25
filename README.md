# lex-agentic-social

Domain consolidation gem for social cognition, governance, and multi-agent interaction. Bundles 17 source extensions into one loadable unit under `Legion::Extensions::Agentic::Social`.

## Overview

**Gem**: `lex-agentic-social`
**Version**: 0.1.0
**Namespace**: `Legion::Extensions::Agentic::Social`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Social::Social` | `lex-social` | Group membership, multi-dimensional reputation, reciprocity, norm violations |
| `Social::TheoryOfMind` | `lex-theory-of-mind` | BDI model — belief/desire/intention tracking, false-belief detection |
| `Social::Mentalizing` | `lex-mentalizing` | Mentalizing network — tracking of mentalizing capacity |
| `Social::SocialLearning` | `lex-social-learning` | Learning by observation — vicarious reinforcement |
| `Social::PerspectiveShifting` | `lex-perspective-shifting` | Deliberate perspective adoption |
| `Social::Trust` | `lex-trust` | Domain-scoped trust scores — asymmetric reinforcement and decay |
| `Social::Conflict` | `lex-conflict` | Conflict registration, severity-based posture, optional LLM resolution |
| `Social::Conscience` | `lex-conscience` | Internalized moral compass — guilt/pride signal generation |
| `Social::Consent` | `lex-consent` | Four-tier consent gradient with earned autonomy, HITL gate |
| `Social::MoralReasoning` | `lex-moral-reasoning` | Six Haidt foundations, six Kohlberg stages, six ethical frameworks |
| `Social::Governance` | `lex-governance` | Four-layer governance — council proposals, quorum voting, action validation |
| `Social::JointAttention` | `lex-joint-attention` | Shared attention between agents — coordinating focus |
| `Social::Mirror` | `lex-mirror` | Mirror neuron analog — action observation and imitation |
| `Social::MirrorSystem` | `lex-mirror` | Extended mirror system |
| `Social::Entrainment` | `lex-cognitive-entrainment` | Rhythmic synchronization between agents |
| `Social::Symbiosis` | `lex-cognitive-symbiosis` | Mutually beneficial cognitive partnerships |
| `Social::Apprenticeship` | `lex-cognitive-apprenticeship` | Expert-novice learning relationships |

## Actors

- `Social::Conflict::Actors::StaleCheck` — runs every 3600s, checks for stale conflicts
- `Social::Consent::Actors::TierEvaluation` — runs every 3600s, evaluates and applies consent tiers
- `Social::Governance::Actors::ShadowAiScan` — interval actor, scans for shadow AI activity
- `Social::Governance::Actors::VoteTimeout` — runs every 300s, times out expired proposals
- `Social::JointAttention::Actors::Decay` — interval actor, decays joint attention focus
- `Social::Mentalizing::Actors::Decay` — interval actor, decays mentalizing model confidence
- `Social::MirrorSystem::Actors::Decay` — interval actor, decays mirror system activation
- `Social::Trust::Actors::Decay` — runs every 300s, decays all trust scores

## Installation

```ruby
gem 'lex-agentic-social'
```

## Development

```bash
bundle install
bundle exec rspec        # 1673 examples, 0 failures
bundle exec rubocop      # 0 offenses
```

## License

MIT
