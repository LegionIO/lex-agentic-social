# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::ObservedBehavior do
  subject(:obs) { described_class.new(agent_id: 'alice', action: :deploy, domain: :infra) }

  describe '#initialize' do
    it 'assigns fields' do
      expect(obs.agent_id).to eq('alice')
      expect(obs.action).to eq(:deploy)
      expect(obs.domain).to eq(:infra)
      expect(obs.observation_count).to eq(1)
    end

    it 'assigns uuid and timestamp' do
      expect(obs.id).to match(/\A[0-9a-f-]{36}\z/)
      expect(obs.created_at).to be_a(Time)
    end

    it 'defaults resonance to DEFAULT_RESONANCE' do
      expect(obs.resonance).to eq(Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::DEFAULT_RESONANCE)
    end

    it 'clamps resonance' do
      high = described_class.new(agent_id: 'a', action: :x, domain: :d, resonance: 5.0)
      expect(high.resonance).to eq(Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::MAX_RESONANCE)
    end
  end

  describe '#observe_again' do
    it 'increments observation count' do
      obs.observe_again
      expect(obs.observation_count).to eq(2)
    end

    it 'boosts resonance by REPETITION_BOOST' do
      before = obs.resonance
      obs.observe_again
      expect(obs.resonance).to be > before
    end
  end

  describe '#boost_familiarity' do
    it 'boosts resonance by FAMILIARITY_BOOST' do
      before = obs.resonance
      obs.boost_familiarity
      boost = Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::FAMILIARITY_BOOST
      expect(obs.resonance).to be_within(0.001).of(before + boost)
    end

    it 'caps at MAX_RESONANCE' do
      obs.resonance = 0.95
      obs.boost_familiarity
      expect(obs.resonance).to eq(Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::MAX_RESONANCE)
    end
  end

  describe '#decay' do
    it 'reduces resonance' do
      before = obs.resonance
      obs.decay
      expect(obs.resonance).to be < before
    end

    it 'does not drop below RESONANCE_FLOOR' do
      50.times { obs.decay }
      expect(obs.resonance).to be >= Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::RESONANCE_FLOOR
    end
  end

  describe '#faded?' do
    it 'returns false for strong observation' do
      expect(obs.faded?).to be false
    end

    it 'returns true at floor' do
      obs.resonance = Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::RESONANCE_FLOOR
      expect(obs.faded?).to be true
    end
  end

  describe '#label' do
    it 'returns :faint for default resonance' do
      expect(obs.label).to eq(:faint)
    end

    it 'returns :strong_mirror for high resonance' do
      obs.resonance = 0.9
      expect(obs.label).to eq(:strong_mirror)
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields' do
      h = obs.to_h
      expect(h).to include(:id, :agent_id, :action, :domain, :resonance, :observation_count, :label, :created_at)
    end
  end
end
