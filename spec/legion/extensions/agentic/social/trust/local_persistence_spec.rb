# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'lex-trust Apollo Local persistence' do
  subject(:map) { described_class.new }

  let(:described_class) { Legion::Extensions::Agentic::Social::Trust::Helpers::TrustMap }

  describe '#dirty?' do
    it 'starts clean' do
      expect(map.dirty?).to be false
    end

    it 'becomes dirty after record_interaction' do
      map.record_interaction('agent-001', positive: true)
      expect(map.dirty?).to be true
    end

    it 'becomes dirty after reinforce_dimension' do
      map.get_or_create('agent-001')
      map.reinforce_dimension('agent-001', dimension: :competence)
      expect(map.dirty?).to be true
    end

    it 'becomes dirty after decay_all with entries' do
      map.get_or_create('agent-001')
      map.decay_all
      expect(map.dirty?).to be true
    end

    it 'stays clean after decay_all with no entries' do
      map.decay_all
      expect(map.dirty?).to be false
    end

    it 'becomes clean after mark_clean!' do
      map.record_interaction('agent-001', positive: true)
      map.mark_clean!
      expect(map.dirty?).to be false
    end
  end

  describe '#mark_clean!' do
    it 'returns self' do
      expect(map.mark_clean!).to eq(map)
    end

    it 'resets dirty flag' do
      map.record_interaction('agent-001', positive: true)
      map.mark_clean!
      expect(map.dirty?).to be false
    end
  end

  describe '#to_apollo_entries' do
    it 'returns empty array when no entries' do
      expect(map.to_apollo_entries).to eq([])
    end

    it 'returns one entry per trust record' do
      map.record_interaction('agent-a', positive: true)
      map.record_interaction('agent-b', positive: false)
      expect(map.to_apollo_entries.size).to eq(2)
    end

    it 'returns separate entries for different domains of the same agent' do
      map.record_interaction('agent-001', positive: true, domain: :code)
      map.record_interaction('agent-001', positive: false, domain: :ops)
      expect(map.to_apollo_entries.size).to eq(2)
    end

    it 'entry content is a JSON string with agent_id' do
      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      parsed = JSON.parse(entry[:content])
      expect(parsed).to have_key('agent_id')
      expect(parsed['agent_id']).to eq('agent-001')
    end

    it 'entry content includes domain' do
      map.record_interaction('agent-001', positive: true, domain: :code)
      entry = map.to_apollo_entries.first
      parsed = JSON.parse(entry[:content])
      expect(parsed['domain']).to eq('code')
    end

    it 'entry content includes all four dimensions' do
      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      parsed = JSON.parse(entry[:content])
      expect(parsed['dimensions']).to have_key('reliability')
      expect(parsed['dimensions']).to have_key('competence')
      expect(parsed['dimensions']).to have_key('integrity')
      expect(parsed['dimensions']).to have_key('benevolence')
    end

    it 'entry content includes composite score' do
      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      parsed = JSON.parse(entry[:content])
      expect(parsed['composite']).to be > 0.3
    end

    it 'entry content includes interaction counts' do
      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      parsed = JSON.parse(entry[:content])
      expect(parsed['interaction_count']).to eq(1)
      expect(parsed['positive_count']).to eq(1)
      expect(parsed['negative_count']).to eq(0)
    end

    it 'entry tags include trust, trust_entry, agent_id, and domain' do
      map.record_interaction('agent-001', positive: true, domain: :code)
      entry = map.to_apollo_entries.first
      expect(entry[:tags]).to include('trust', 'trust_entry', 'agent-001', 'code')
    end

    it 'entry tags include partner when BondRegistry reports partner' do
      bond_registry = Module.new do
        def self.partner?(agent_id)
          agent_id == 'agent-001'
        end
      end
      stub_const('Legion::Gaia::BondRegistry', bond_registry)

      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      expect(entry[:tags]).to include('partner')
    end

    it 'entry tags exclude partner for non-partner agents' do
      bond_registry = Module.new do
        def self.partner?(_agent_id)
          false
        end
      end
      stub_const('Legion::Gaia::BondRegistry', bond_registry)

      map.record_interaction('agent-001', positive: true)
      entry = map.to_apollo_entries.first
      expect(entry[:tags]).not_to include('partner')
    end
  end

  describe '#from_apollo' do
    let(:mock_store) do
      double('ApolloLocal').tap do |store|
        allow(store).to receive(:query).and_return({ success: false, results: [] })
      end
    end

    it 'returns false when store query fails or returns no results' do
      result = map.from_apollo(store: mock_store)
      expect(result).to be false
    end

    it 'populates entries from stored JSON' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'general',
                            dimensions: { reliability: 0.6, competence: 0.5, integrity: 0.4, benevolence: 0.3 },
                            composite: 0.45, interaction_count: 3, positive_count: 3, negative_count: 0,
                            last_interaction: Time.now.utc.iso8601, created_at: Time.now.utc.iso8601
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 general] }] }
      )
      map.from_apollo(store: mock_store)
      expect(map.get('agent-001')).not_to be_nil
    end

    it 'restores domain as a symbol' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'code',
                            dimensions: { reliability: 0.3, competence: 0.3, integrity: 0.3, benevolence: 0.3 },
                            composite: 0.3, interaction_count: 0, positive_count: 0, negative_count: 0
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 code] }] }
      )
      map.from_apollo(store: mock_store)
      entry = map.get('agent-001', domain: :code)
      expect(entry).not_to be_nil
      expect(entry[:domain]).to eq(:code)
    end

    it 'restores all four dimension values' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'general',
                            dimensions: { reliability: 0.6, competence: 0.5, integrity: 0.4, benevolence: 0.3 },
                            composite: 0.45, interaction_count: 0, positive_count: 0, negative_count: 0
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 general] }] }
      )
      map.from_apollo(store: mock_store)
      entry = map.get('agent-001')
      expect(entry[:dimensions][:reliability]).to be_within(0.0001).of(0.6)
      expect(entry[:dimensions][:competence]).to be_within(0.0001).of(0.5)
      expect(entry[:dimensions][:integrity]).to be_within(0.0001).of(0.4)
      expect(entry[:dimensions][:benevolence]).to be_within(0.0001).of(0.3)
    end

    it 'restores multiple entries' do
      content_a = JSON.dump({
                              agent_id: 'agent-a', domain: 'general',
                              dimensions: { reliability: 0.3, competence: 0.3, integrity: 0.3, benevolence: 0.3 },
                              composite: 0.3, interaction_count: 0, positive_count: 0, negative_count: 0
                            })
      content_b = JSON.dump({
                              agent_id: 'agent-b', domain: 'ops',
                              dimensions: { reliability: 0.3, competence: 0.3, integrity: 0.3, benevolence: 0.3 },
                              composite: 0.3, interaction_count: 0, positive_count: 0, negative_count: 0
                            })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [
          { content: content_a, tags: %w[trust trust_entry agent-a general] },
          { content: content_b, tags: %w[trust trust_entry agent-b ops] }
        ] }
      )
      map.from_apollo(store: mock_store)
      expect(map.count).to eq(2)
    end

    it 'restores interaction counts' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'general',
                            dimensions: { reliability: 0.45, competence: 0.45, integrity: 0.45, benevolence: 0.45 },
                            composite: 0.45, interaction_count: 5, positive_count: 3, negative_count: 2
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 general] }] }
      )
      map.from_apollo(store: mock_store)
      entry = map.get('agent-001')
      expect(entry[:interaction_count]).to eq(5)
      expect(entry[:positive_count]).to eq(3)
      expect(entry[:negative_count]).to eq(2)
    end

    it 'allows normal operations on restored entries' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'general',
                            dimensions: { reliability: 0.4, competence: 0.4, integrity: 0.4, benevolence: 0.4 },
                            composite: 0.4, interaction_count: 2, positive_count: 2, negative_count: 0
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 general] }] }
      )
      map.from_apollo(store: mock_store)
      map.record_interaction('agent-001', positive: true)
      entry = map.get('agent-001')
      expect(entry[:interaction_count]).to eq(3)
      expect(entry[:positive_count]).to eq(3)
    end

    it 'trusted_agents works correctly after hydration' do
      content = JSON.dump({
                            agent_id: 'agent-001', domain: 'general',
                            dimensions: { reliability: 0.6, competence: 0.6, integrity: 0.6, benevolence: 0.6 },
                            composite: 0.6, interaction_count: 5, positive_count: 5, negative_count: 0
                          })
      allow(mock_store).to receive(:query).and_return(
        { success: true, results: [{ content: content, tags: %w[trust trust_entry agent-001 general] }] }
      )
      map.from_apollo(store: mock_store)
      trusted = map.trusted_agents
      expect(trusted).not_to be_empty
      expect(trusted.first[:agent_id]).to eq('agent-001')
    end
  end

  describe 'round-trip via to_apollo_entries / from_apollo' do
    let(:mock_store) { double('ApolloLocal') }

    it 'preserves trust scores across serialize/deserialize' do
      5.times { map.record_interaction('agent-001', positive: true) }
      composite_before = map.get('agent-001')[:composite]

      entries = map.to_apollo_entries
      allow(mock_store).to receive(:query).and_return({ success: true, results: entries })

      map2 = described_class.new
      map2.from_apollo(store: mock_store)
      expect(map2.get('agent-001')[:composite]).to be_within(0.0001).of(composite_before)
    end

    it 'round-trips interaction counts accurately' do
      3.times { map.record_interaction('agent-001', positive: true) }
      2.times { map.record_interaction('agent-001', positive: false) }

      entries = map.to_apollo_entries
      allow(mock_store).to receive(:query).and_return({ success: true, results: entries })

      map2 = described_class.new
      map2.from_apollo(store: mock_store)
      entry = map2.get('agent-001')
      expect(entry[:interaction_count]).to eq(5)
      expect(entry[:positive_count]).to eq(3)
      expect(entry[:negative_count]).to eq(2)
    end

    it 'round-trips multiple agents independently' do
      5.times { map.record_interaction('agent-high', positive: true) }
      map.record_interaction('agent-low', positive: false)

      entries = map.to_apollo_entries
      allow(mock_store).to receive(:query).and_return({ success: true, results: entries })

      map2 = described_class.new
      map2.from_apollo(store: mock_store)
      expect(map2.get('agent-high')[:composite]).to be > map2.get('agent-low')[:composite]
    end

    it 'round-trips domain-scoped entries independently' do
      5.times { map.record_interaction('agent-001', positive: true, domain: :code) }
      map.record_interaction('agent-001', positive: false, domain: :ops)

      entries = map.to_apollo_entries
      allow(mock_store).to receive(:query).and_return({ success: true, results: entries })

      map2 = described_class.new
      map2.from_apollo(store: mock_store)
      code_entry = map2.get('agent-001', domain: :code)
      ops_entry  = map2.get('agent-001', domain: :ops)
      expect(code_entry[:composite]).to be > ops_entry[:composite]
    end

    it 'round-trips all four dimension values' do
      map.record_interaction('agent-001', positive: true)
      map.reinforce_dimension('agent-001', dimension: :competence, amount: 0.2)

      entries = map.to_apollo_entries
      allow(mock_store).to receive(:query).and_return({ success: true, results: entries })

      map2 = described_class.new
      map2.from_apollo(store: mock_store)
      original = map.get('agent-001')[:dimensions]
      restored = map2.get('agent-001')[:dimensions]
      Legion::Extensions::Agentic::Social::Trust::Helpers::TrustModel::TRUST_DIMENSIONS.each do |dim|
        expect(restored[dim]).to be_within(0.0001).of(original[dim])
      end
    end
  end
end
