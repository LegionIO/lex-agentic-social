# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MirrorSystem::Runners::Mirror do
  let(:client) { Legion::Extensions::Agentic::Social::MirrorSystem::Client.new }

  describe '#observe_behavior' do
    it 'creates an observation' do
      result = client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      expect(result[:success]).to be true
      expect(result[:observation][:agent_id]).to eq('alice')
      expect(result[:observation][:action]).to eq(:deploy)
    end

    it 'boosts resonance on repeat observation' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      result = client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      expect(result[:observation][:observation_count]).to eq(2)
    end
  end

  describe '#imitate_behavior' do
    it 'returns imitated: false with no observations' do
      result = client.imitate_behavior(action: :deploy, domain: :infra)
      expect(result[:success]).to be true
      expect(result[:imitated]).to be false
    end

    it 'imitates observed behavior' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      result = client.imitate_behavior(action: :deploy, domain: :infra)
      expect(result[:imitated]).to be true
      expect(result[:source]).to eq('alice')
      expect(result[:fidelity]).to be_a(Float)
    end

    it 'filters by source_agent' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      client.observe_behavior(agent_id: 'bob', action: :deploy, domain: :infra)
      result = client.imitate_behavior(action: :deploy, domain: :infra, source_agent: 'bob')
      expect(result[:source]).to eq('bob')
    end
  end

  describe '#report_imitation_outcome' do
    it 'updates fidelity on success' do
      result = client.report_imitation_outcome(action: :deploy, domain: :infra, success_flag: true)
      expect(result[:success]).to be true
      expect(result[:fidelity]).to be > Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::DEFAULT_FIDELITY
    end

    it 'updates fidelity on failure' do
      result = client.report_imitation_outcome(action: :deploy, domain: :infra, success_flag: false)
      expect(result[:fidelity]).to be < Legion::Extensions::Agentic::Social::MirrorSystem::Helpers::Constants::DEFAULT_FIDELITY
    end
  end

  describe '#strongest_mirrors' do
    it 'returns top mirrors' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      client.observe_behavior(agent_id: 'bob', action: :test, domain: :code)
      result = client.strongest_mirrors(count: 2)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end
  end

  describe '#observations_for' do
    it 'returns observations for agent' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      client.observe_behavior(agent_id: 'alice', action: :test, domain: :code)
      result = client.observations_for(agent_id: 'alice')
      expect(result[:count]).to eq(2)
    end

    it 'returns empty for unknown agent' do
      result = client.observations_for(agent_id: 'nobody')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#observations_in' do
    it 'returns observations in domain' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      client.observe_behavior(agent_id: 'bob', action: :test, domain: :code)
      result = client.observations_in(domain: :infra)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#repertoire_status' do
    it 'starts empty' do
      result = client.repertoire_status
      expect(result[:size]).to eq(0)
    end

    it 'grows after imitation' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      client.imitate_behavior(action: :deploy, domain: :infra)
      result = client.repertoire_status
      expect(result[:size]).to eq(1)
    end
  end

  describe '#update_mirror' do
    it 'decays and returns stats' do
      client.observe_behavior(agent_id: 'alice', action: :deploy, domain: :infra)
      result = client.update_mirror
      expect(result[:success]).to be true
      expect(result).to have_key(:observations)
      expect(result).to have_key(:repertoire)
      expect(result).to have_key(:agents)
    end
  end

  describe '#mirror_stats' do
    it 'returns comprehensive stats' do
      result = client.mirror_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:observations, :repertoire_size, :mirrored_agents)
    end
  end
end
