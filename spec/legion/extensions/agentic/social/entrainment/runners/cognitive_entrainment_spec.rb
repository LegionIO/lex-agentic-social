# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Entrainment::Runners::CognitiveEntrainment do
  let(:runner_host) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#create_entrainment_pairing' do
    it 'creates a pairing' do
      result = runner_host.create_entrainment_pairing(
        agent_a: 'alpha', agent_b: 'beta', domain: :reasoning
      )
      expect(result[:success]).to be true
      expect(result[:pairing_id]).to be_a(String)
    end
  end

  describe '#record_entrainment_interaction' do
    it 'records an interaction' do
      created = runner_host.create_entrainment_pairing(
        agent_a: 'alpha', agent_b: 'beta', domain: :reasoning
      )
      result = runner_host.record_entrainment_interaction(
        pairing_id: created[:pairing_id], aligned: true
      )
      expect(result[:success]).to be true
    end
  end

  describe '#pairings_for_agent' do
    it 'finds pairings for an agent' do
      runner_host.create_entrainment_pairing(
        agent_a: 'alpha', agent_b: 'beta', domain: :reasoning
      )
      result = runner_host.pairings_for_agent(agent_id: 'alpha')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#entrained_partners' do
    it 'returns entrained partners' do
      result = runner_host.entrained_partners(agent_id: 'alpha')
      expect(result[:success]).to be true
    end
  end

  describe '#strongest_entrainment_pairings' do
    it 'returns strongest pairings' do
      result = runner_host.strongest_entrainment_pairings(limit: 3)
      expect(result[:success]).to be true
    end
  end

  describe '#domain_entrainment' do
    it 'returns pairings by domain' do
      result = runner_host.domain_entrainment(domain: :reasoning)
      expect(result[:success]).to be true
    end
  end

  describe '#overall_entrainment_level' do
    it 'returns overall synchrony' do
      result = runner_host.overall_entrainment_level
      expect(result[:success]).to be true
      expect(result).to include(:overall_synchrony)
    end
  end

  describe '#update_cognitive_entrainment' do
    it 'runs drift and prune' do
      result = runner_host.update_cognitive_entrainment
      expect(result[:success]).to be true
      expect(result).to include(:pruned)
    end
  end

  describe '#cognitive_entrainment_stats' do
    it 'returns stats' do
      result = runner_host.cognitive_entrainment_stats
      expect(result[:success]).to be true
      expect(result).to include(:total_pairings, :entrained_count)
    end
  end
end
