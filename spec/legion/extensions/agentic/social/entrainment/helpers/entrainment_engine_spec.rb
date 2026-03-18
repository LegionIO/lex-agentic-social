# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Entrainment::Helpers::EntrainmentEngine do
  subject(:engine) { described_class.new }

  let(:pairing) { engine.create_pairing(agent_a: 'alpha', agent_b: 'beta', domain: :reasoning) }

  describe '#create_pairing' do
    it 'creates a pairing' do
      result = pairing
      expect(result).to be_a(Legion::Extensions::Agentic::Social::Entrainment::Helpers::Pairing)
    end

    it 'returns existing pairing for same agents and domain' do
      first = pairing
      second = engine.create_pairing(agent_a: 'alpha', agent_b: 'beta', domain: :reasoning)
      expect(second.id).to eq(first.id)
    end

    it 'records history' do
      pairing
      expect(engine.history.size).to eq(1)
    end
  end

  describe '#record_interaction' do
    it 'records an aligned interaction' do
      result = engine.record_interaction(pairing_id: pairing.id, aligned: true)
      expect(result[:success]).to be true
      expect(result[:synchrony]).to be > 0.0
    end

    it 'returns error for unknown pairing' do
      result = engine.record_interaction(pairing_id: 'bad', aligned: true)
      expect(result[:success]).to be false
    end
  end

  describe '#pairings_for' do
    it 'finds pairings involving an agent' do
      pairing
      results = engine.pairings_for(agent_id: 'alpha')
      expect(results.size).to eq(1)
    end
  end

  describe '#entrained_pairings' do
    it 'returns entrained pairings' do
      10.times { engine.record_interaction(pairing_id: pairing.id, aligned: true) }
      expect(engine.entrained_pairings.size).to eq(1)
    end
  end

  describe '#entrained_partners' do
    it 'returns entrained partner agent ids' do
      10.times { engine.record_interaction(pairing_id: pairing.id, aligned: true) }
      partners = engine.entrained_partners(agent_id: 'alpha')
      expect(partners).to include('beta')
    end
  end

  describe '#strongest_pairings' do
    it 'returns sorted by synchrony' do
      other = engine.create_pairing(agent_a: 'alpha', agent_b: 'gamma', domain: :planning)
      5.times { engine.record_interaction(pairing_id: pairing.id, aligned: true) }
      2.times { engine.record_interaction(pairing_id: other.id, aligned: true) }
      results = engine.strongest_pairings(limit: 2)
      expect(results.first.synchrony).to be >= results.last.synchrony
    end
  end

  describe '#by_domain' do
    it 'filters by domain' do
      pairing
      results = engine.by_domain(domain: :reasoning)
      expect(results.size).to eq(1)
    end
  end

  describe '#overall_entrainment' do
    it 'returns 0.0 with no pairings' do
      expect(engine.overall_entrainment).to eq(0.0)
    end

    it 'returns mean synchrony' do
      3.times { engine.record_interaction(pairing_id: pairing.id, aligned: true) }
      expect(engine.overall_entrainment).to be > 0.0
    end
  end

  describe '#drift_all' do
    it 'reduces synchrony' do
      5.times { engine.record_interaction(pairing_id: pairing.id, aligned: true) }
      original = pairing.synchrony
      engine.drift_all
      expect(pairing.synchrony).to be < original
    end
  end

  describe '#prune_independent' do
    it 'removes very low synchrony pairings' do
      pairing
      pruned = engine.prune_independent
      expect(pruned).to be >= 1
    end
  end

  describe '#to_h' do
    it 'returns summary stats' do
      pairing
      stats = engine.to_h
      expect(stats[:total_pairings]).to be >= 0
      expect(stats).to include(:entrained_count, :overall_sync)
    end
  end
end
