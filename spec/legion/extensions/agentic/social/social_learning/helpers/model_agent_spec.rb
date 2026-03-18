# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Helpers::ModelAgent do
  subject(:model) do
    described_class.new(agent_id: 'agent-abc', domain: :ops, prestige: 0.5)
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(model.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets the agent_id' do
      expect(model.agent_id).to eq('agent-abc')
    end

    it 'sets prestige' do
      expect(model.prestige).to eq(0.5)
    end

    it 'starts with zero observation_count' do
      expect(model.observation_count).to eq(0)
    end

    it 'starts with empty observed_behaviors' do
      expect(model.observed_behaviors).to be_empty
    end

    it 'clamps prestige above ceiling to 1.0' do
      m = described_class.new(agent_id: 'x', domain: :test, prestige: 5.0)
      expect(m.prestige).to eq(1.0)
    end

    it 'clamps prestige below floor to 0.0' do
      m = described_class.new(agent_id: 'x', domain: :test, prestige: -1.0)
      expect(m.prestige).to eq(0.0)
    end
  end

  describe '#observe!' do
    let(:fake_behavior) { double('ObservedBehavior') }

    it 'increments observation_count' do
      expect { model.observe!(behavior: fake_behavior, outcome: :neutral) }
        .to change(model, :observation_count).by(1)
    end

    it 'increases prestige on positive outcome' do
      before = model.prestige
      model.observe!(behavior: fake_behavior, outcome: :positive)
      expect(model.prestige).to be > before
    end

    it 'decreases prestige on negative outcome' do
      before = model.prestige
      model.observe!(behavior: fake_behavior, outcome: :negative)
      expect(model.prestige).to be < before
    end

    it 'does not change prestige on neutral outcome' do
      before = model.prestige
      model.observe!(behavior: fake_behavior, outcome: :neutral)
      expect(model.prestige).to eq(before)
    end

    it 'tracks success_count for positive outcomes' do
      model.observe!(behavior: fake_behavior, outcome: :positive)
      expect(model.success_count).to eq(1)
    end
  end

  describe '#prestige_label' do
    it 'returns :expert for prestige >= 0.8' do
      model.prestige = 0.9
      expect(model.prestige_label).to eq(:expert)
    end

    it 'returns :proficient for prestige in 0.6...0.8' do
      model.prestige = 0.7
      expect(model.prestige_label).to eq(:proficient)
    end

    it 'returns :peer for prestige in 0.4...0.6' do
      model.prestige = 0.5
      expect(model.prestige_label).to eq(:peer)
    end

    it 'returns :novice for prestige in 0.2...0.4' do
      model.prestige = 0.3
      expect(model.prestige_label).to eq(:novice)
    end

    it 'returns :unreliable for prestige below 0.2' do
      model.prestige = 0.1
      expect(model.prestige_label).to eq(:unreliable)
    end
  end

  describe '#success_rate' do
    it 'returns 0.0 with no observations' do
      expect(model.success_rate).to eq(0.0)
    end

    it 'returns correct ratio after observations' do
      fake_behavior = double('ObservedBehavior')
      model.observe!(behavior: fake_behavior, outcome: :positive)
      model.observe!(behavior: fake_behavior, outcome: :negative)
      expect(model.success_rate).to eq(0.5)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      hash = model.to_h
      expect(hash).to include(:id, :agent_id, :domain, :prestige, :prestige_label,
                              :observation_count, :success_count, :success_rate,
                              :behavior_count, :created_at)
    end
  end
end
