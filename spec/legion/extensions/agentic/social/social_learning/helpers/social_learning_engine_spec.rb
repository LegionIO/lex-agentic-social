# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Helpers::SocialLearningEngine do
  subject(:engine) { described_class.new }

  let(:model) { engine.register_model(agent_id: 'agent-1', domain: :coding) }

  describe '#register_model' do
    it 'returns a ModelAgent' do
      expect(model).to be_a(Legion::Extensions::Agentic::Social::SocialLearning::Helpers::ModelAgent)
    end

    it 'assigns agent_id and domain' do
      expect(model.agent_id).to eq('agent-1')
      expect(model.domain).to eq(:coding)
    end

    it 'uses DEFAULT_PRESTIGE when none given' do
      expect(model.prestige).to eq(Legion::Extensions::Agentic::Social::SocialLearning::Helpers::Constants::DEFAULT_PRESTIGE)
    end
  end

  describe '#observe_behavior' do
    it 'returns nil for unknown model' do
      result = engine.observe_behavior(
        model_id: 'nonexistent', action: 'do_thing', domain: :coding, outcome: :positive
      )
      expect(result).to be_nil
    end

    it 'returns nil when model prestige is below ATTENTION_THRESHOLD' do
      low_model = engine.register_model(agent_id: 'low', domain: :coding, prestige: 0.1)
      result = engine.observe_behavior(
        model_id: low_model.id, action: 'do_thing', domain: :coding, outcome: :positive
      )
      expect(result).to be_nil
    end

    it 'returns an ObservedBehavior when model passes attention threshold' do
      behavior = engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
      expect(behavior).to be_a(Legion::Extensions::Agentic::Social::SocialLearning::Helpers::ObservedBehavior)
    end

    it 'updates model prestige on positive outcome' do
      before = model.prestige
      engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
      expect(model.prestige).to be > before
    end
  end

  describe '#retained_behaviors' do
    before do
      engine.observe_behavior(
        model_id: model.id, action: 'action_a', domain: :coding, outcome: :positive
      )
    end

    it 'returns behaviors with retention above REPRODUCTION_CONFIDENCE' do
      result = engine.retained_behaviors
      expect(result).not_to be_empty
    end

    it 'filters by domain when given' do
      engine.observe_behavior(
        model_id: model.id, action: 'action_b', domain: :ops, outcome: :positive
      )
      result = engine.retained_behaviors(domain: :coding)
      expect(result.all? { |beh| beh.domain == :coding }).to be true
    end
  end

  describe '#reproducible_behaviors' do
    it 'returns behaviors above REPRODUCTION_CONFIDENCE' do
      engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
      result = engine.reproducible_behaviors
      expect(result).not_to be_empty
    end
  end

  describe '#reproduce_behavior' do
    let(:behavior) do
      engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
    end

    it 'marks the behavior as reproduced' do
      engine.reproduce_behavior(behavior_id: behavior.id)
      expect(behavior.reproduced).to be true
    end

    it 'returns nil for unknown behavior_id' do
      result = engine.reproduce_behavior(behavior_id: 'nonexistent')
      expect(result).to be_nil
    end
  end

  describe '#reinforce_reproduction' do
    let(:behavior) do
      engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
    end

    it 'boosts model prestige on positive outcome' do
      before = model.prestige
      engine.reinforce_reproduction(behavior_id: behavior.id, outcome: :positive)
      expect(model.prestige).to be > before
    end

    it 'penalizes model prestige on negative outcome' do
      before = model.prestige
      engine.reinforce_reproduction(behavior_id: behavior.id, outcome: :negative)
      expect(model.prestige).to be < before
    end

    it 'returns nil for unknown behavior_id' do
      result = engine.reinforce_reproduction(behavior_id: 'nonexistent', outcome: :positive)
      expect(result).to be_nil
    end

    it 'returns a hash with behavior and model_prestige' do
      result = engine.reinforce_reproduction(behavior_id: behavior.id, outcome: :positive)
      expect(result).to include(:behavior, :model_prestige)
    end
  end

  describe '#best_models' do
    before do
      engine.register_model(agent_id: 'agent-2', domain: :ops,    prestige: 0.9)
      engine.register_model(agent_id: 'agent-3', domain: :coding, prestige: 0.3)
    end

    it 'returns models sorted by prestige descending' do
      models = engine.best_models(limit: 3)
      prestiges = models.map(&:prestige)
      expect(prestiges).to eq(prestiges.sort.reverse)
    end

    it 'respects the limit' do
      models = engine.best_models(limit: 2)
      expect(models.size).to be <= 2
    end
  end

  describe '#by_domain' do
    before do
      engine.register_model(agent_id: 'agent-ops', domain: :ops)
    end

    it 'returns only models in the given domain' do
      result = engine.by_domain(domain: :ops)
      expect(result.all? { |mod| mod.domain == :ops }).to be true
    end

    it 'returns empty array for unknown domain' do
      result = engine.by_domain(domain: :unknown_domain)
      expect(result).to be_empty
    end
  end

  describe '#decay_all' do
    it 'decays retention on all behaviors' do
      behavior = engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
      before = behavior.retention
      engine.decay_all
      expect(behavior.retention).to be < before
    end
  end

  describe '#prune_forgotten' do
    it 'removes behaviors below 0.05 retention' do
      behavior = engine.observe_behavior(
        model_id: model.id, action: 'write_test', domain: :coding, outcome: :positive
      )
      behavior.retention = 0.04
      engine.prune_forgotten
      expect(engine.retained_behaviors).not_to include(behavior)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      result = engine.to_h
      expect(result).to include(:model_count, :behavior_count, :retained_count, :reproducible_count)
    end
  end
end
