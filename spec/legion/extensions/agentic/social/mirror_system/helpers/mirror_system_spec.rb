# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::MirrorSystem do
  subject(:system) { described_class.new }

  describe '#observe' do
    it 'creates a new observation' do
      obs = system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      expect(obs).to be_a(Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::ObservedBehavior)
      expect(system.observation_count).to eq(1)
    end

    it 'increments count on repeated observation' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      obs = system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      expect(obs.observation_count).to eq(2)
      expect(system.observation_count).to eq(1)
    end

    it 'boosts familiarity when behavior is in repertoire' do
      system.add_to_repertoire(:deploy, :infra)
      obs = system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      default = Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::DEFAULT_RESONANCE
      boost = Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::FAMILIARITY_BOOST
      expect(obs.resonance).to be_within(0.001).of(default + boost)
    end

    it 'tracks separate observations per agent' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      system.observe(agent_id: 'bob', action: :deploy, domain: :infra)
      expect(system.observation_count).to eq(2)
    end
  end

  describe '#imitate' do
    it 'returns nil when no observations exist' do
      expect(system.imitate(action: :deploy, domain: :infra)).to be_nil
    end

    it 'imitates observed behavior and adds to repertoire' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      result = system.imitate(action: :deploy, domain: :infra)
      expect(result).not_to be_nil
      expect(result[:observation].agent_id).to eq('alice')
      expect(result[:fidelity]).to be_a(Float)
      expect(system.repertoire_includes?(:deploy, :infra)).to be true
    end

    it 'filters by source_agent when specified' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      system.observe(agent_id: 'bob', action: :deploy, domain: :infra)
      result = system.imitate(action: :deploy, domain: :infra, source_agent: 'alice')
      expect(result[:observation].agent_id).to eq('alice')
    end

    it 'picks highest resonance observation' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      obs_bob = system.observe(agent_id: 'bob', action: :deploy, domain: :infra)
      obs_bob.resonance = 0.9
      result = system.imitate(action: :deploy, domain: :infra)
      expect(result[:observation].agent_id).to eq('bob')
    end
  end

  describe '#update_fidelity' do
    it 'increases fidelity on success' do
      before = system.fidelity_for(:deploy, :infra)
      system.update_fidelity(action: :deploy, domain: :infra, success: true)
      expect(system.fidelity_for(:deploy, :infra)).to be > before
    end

    it 'decreases fidelity on failure' do
      before = system.fidelity_for(:deploy, :infra)
      system.update_fidelity(action: :deploy, domain: :infra, success: false)
      expect(system.fidelity_for(:deploy, :infra)).to be < before
    end

    it 'clamps to 0..1' do
      20.times { system.update_fidelity(action: :deploy, domain: :infra, success: true) }
      expect(system.fidelity_for(:deploy, :infra)).to be <= 1.0
    end
  end

  describe '#observations_for_agent' do
    it 'returns observations by specific agent' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      system.observe(agent_id: 'alice', action: :test, domain: :infra)
      system.observe(agent_id: 'bob', action: :deploy, domain: :infra)
      expect(system.observations_for_agent('alice').size).to eq(2)
    end
  end

  describe '#observations_in_domain' do
    it 'returns observations in domain' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      system.observe(agent_id: 'alice', action: :test, domain: :code)
      expect(system.observations_in_domain(:infra).size).to eq(1)
    end
  end

  describe '#strongest_mirrors' do
    it 'returns top N by resonance' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      obs = system.observe(agent_id: 'bob', action: :test, domain: :code)
      obs.resonance = 0.9
      top = system.strongest_mirrors(1)
      expect(top.size).to eq(1)
      expect(top.first.agent_id).to eq('bob')
    end
  end

  describe '#decay_all' do
    it 'decays all observations' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      before = system.observations.values.first.resonance
      system.decay_all
      after = system.observations.values.first&.resonance
      expect(after).to be < before if after
    end

    it 'prunes faded observations' do
      obs = system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      obs.resonance = Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::RESONANCE_FLOOR + 0.005
      system.decay_all
      expect(system.observation_count).to eq(0)
    end
  end

  describe '#mirrored_agents' do
    it 'lists unique observed agents' do
      system.observe(agent_id: 'alice', action: :deploy, domain: :infra)
      system.observe(agent_id: 'bob', action: :test, domain: :code)
      system.observe(agent_id: 'alice', action: :test, domain: :code)
      expect(system.mirrored_agents).to contain_exactly('alice', 'bob')
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      h = system.to_h
      expect(h).to include(:observations, :repertoire_size, :mirrored_agents, :history_size)
    end
  end
end
