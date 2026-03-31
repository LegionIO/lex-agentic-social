# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/social/attachment/helpers/constants'
require 'legion/extensions/agentic/social/attachment/helpers/attachment_model'
require 'legion/extensions/agentic/social/attachment/helpers/attachment_store'
require 'legion/extensions/agentic/social/attachment/runners/attachment'

RSpec.describe Legion::Extensions::Agentic::Social::Attachment::Runners::Attachment do
  let(:host) { Object.new.extend(described_class) }

  before do
    # Reset memoized store between specs
    host.instance_variable_set(:@attachment_store, nil)
  end

  describe '#update_attachment' do
    let(:tick_results) do
      {
        social_cognition: {
          reputation_updates: [
            { agent_id: 'partner-1', composite: 0.6 }
          ],
          reciprocity_ledger_size: 10
        },
        theory_of_mind: {
          prediction_accuracy: { 'partner-1' => 0.7 }
        }
      }
    end

    let(:human_observations) do
      [
        { agent_id: 'partner-1', direct_address: true, channel: 'teams' },
        { agent_id: 'partner-1', direct_address: false, channel: 'teams' },
        { agent_id: 'partner-1', direct_address: true, channel: 'cli' }
      ]
    end

    it 'returns a result hash' do
      result = host.update_attachment(tick_results: tick_results, human_observations: human_observations)
      expect(result).to be_a(Hash)
      expect(result).to have_key(:agents_updated)
    end

    it 'creates a model for observed agents' do
      host.update_attachment(tick_results: tick_results, human_observations: human_observations)
      store = host.send(:attachment_store)
      expect(store.get('partner-1')).not_to be_nil
    end

    it 'updates attachment strength' do
      host.update_attachment(tick_results: tick_results, human_observations: human_observations)
      model = host.send(:attachment_store).get('partner-1')
      expect(model.attachment_strength).to be > 0.0
    end

    it 'marks store dirty' do
      host.update_attachment(tick_results: tick_results, human_observations: human_observations)
      expect(host.send(:attachment_store)).to be_dirty
    end

    it 'handles empty tick results' do
      result = host.update_attachment(tick_results: {}, human_observations: [])
      expect(result[:agents_updated]).to eq(0)
    end
  end

  describe '#reflect_on_bonds' do
    let(:mock_store) { double('apollo_local') }

    before do
      allow(host).to receive(:apollo_local_store).and_return(mock_store)
      allow(mock_store).to receive(:query).and_return({ success: true, results: [] })

      store = host.send(:attachment_store)
      model = store.get_or_create('partner-1')
      model.update_from_signals(frequency_score: 0.6, reciprocity_score: 0.5,
                                prediction_accuracy: 0.7, direct_address_ratio: 0.4,
                                channel_consistency: 0.8)
      model.instance_variable_set(:@interaction_count, 55)
      model.instance_variable_set(:@bond_stage, :established)
    end

    it 'returns bond reflection result' do
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(result).to have_key(:bonds_reflected)
      expect(result).to have_key(:partner_bond)
    end

    it 'includes partner bond state' do
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      bond = result[:partner_bond]
      expect(bond[:stage]).to eq(:established)
      expect(bond[:strength]).to be > 0.0
    end

    it 'reads communication patterns from Apollo Local' do
      host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(mock_store).to have_received(:query)
        .with(hash_including(tags: array_including('bond', 'communication_pattern')))
    end

    it 'reads relationship arc from Apollo Local' do
      host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(mock_store).to have_received(:query)
        .with(hash_including(tags: array_including('bond', 'relationship_arc')))
    end

    it 'returns error when no store available' do
      allow(host).to receive(:apollo_local_store).and_return(nil)
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(result[:success]).to be false
    end

    it 'computes relationship health' do
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(result[:partner_bond][:health]).to be_a(Float)
      expect(result[:partner_bond][:health]).to be_between(0.0, 1.0)
    end
  end

  describe '#attachment_stats' do
    it 'returns stats hash' do
      result = host.attachment_stats
      expect(result).to have_key(:bonds_tracked)
      expect(result).to have_key(:partner_bond)
    end
  end
end
