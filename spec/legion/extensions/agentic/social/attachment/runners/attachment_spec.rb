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
          reputation_updates:      [
            { agent_id: 'partner-1', composite: 0.6 }
          ],
          reciprocity_ledger_size: 10
        },
        theory_of_mind:   {
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
      expect(mock_store).to have_received(:query).at_least(:once)
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

  describe '#compute_frequency_variance' do
    it 'returns 0.0 for fewer than 3 observations' do
      obs = [{ timestamp: Time.now }, { timestamp: Time.now }]
      expect(host.send(:compute_frequency_variance, obs)).to eq(0.0)
    end

    it 'returns 0.0 when observations have no timestamps' do
      obs = [{ agent_id: 'x' }, { agent_id: 'x' }, { agent_id: 'x' }]
      expect(host.send(:compute_frequency_variance, obs)).to eq(0.0)
    end

    it 'returns a positive value for unevenly distributed timestamps' do
      base = Time.now
      # Cluster 6 in one bucket and 1 in another — high variance
      ts = Array.new(6) { base } + [base + 7200]
      obs = ts.map { |t| { timestamp: t } }
      result = host.send(:compute_frequency_variance, obs)
      expect(result).to be > 0.0
      expect(result).to be_between(0.0, 1.0)
    end

    it 'returns low variance for evenly distributed timestamps' do
      base = Time.now
      # One per hour — perfectly even
      ts = (0..4).map { |i| base + (i * 3600) }
      obs = ts.map { |t| { timestamp: t } }
      result = host.send(:compute_frequency_variance, obs)
      expect(result).to eq(0.0)
    end

    it 'uses :observed_at field when present' do
      base = Time.now
      ts = Array.new(5) { base } + [base + 7200]
      obs = ts.map { |t| { observed_at: t } }
      result = host.send(:compute_frequency_variance, obs)
      expect(result).to be > 0.0
    end
  end

  describe '#compute_reciprocity_imbalance' do
    it 'returns 0.0 for empty observations' do
      expect(host.send(:compute_reciprocity_imbalance, [])).to eq(0.0)
    end

    it 'returns 0.0 for balanced initiated/received' do
      obs = [
        { direction: :outgoing },
        { direction: :incoming }
      ]
      expect(host.send(:compute_reciprocity_imbalance, obs)).to eq(0.0)
    end

    it 'returns 1.0 when all interactions are agent-initiated' do
      obs = Array.new(4) { { initiated_by: :agent } }
      expect(host.send(:compute_reciprocity_imbalance, obs)).to eq(1.0)
    end

    it 'returns 1.0 when all interactions are received' do
      obs = Array.new(4) { { direction: :incoming } }
      expect(host.send(:compute_reciprocity_imbalance, obs)).to eq(1.0)
    end

    it 'computes partial imbalance correctly' do
      # 3 outgoing, 1 incoming => |3-1|/4 = 0.5
      obs = Array.new(3) { { direction: :outgoing } } + [{ direction: :incoming }]
      expect(host.send(:compute_reciprocity_imbalance, obs)).to be_within(0.001).of(0.5)
    end
  end

  describe '#extract_style_signals — anxious style reachability' do
    it 'produces frequency_variance and reciprocity_imbalance values that can trigger anxious style' do
      base = Time.now
      # 6 in one bucket + 1 isolated — high frequency variance
      timestamps = Array.new(6) { base } + [base + 7200]
      # All agent-initiated — max reciprocity imbalance
      obs = timestamps.map.with_index do |t, i|
        { agent_id: 'partner-1', timestamp: t, initiated_by: :agent, direction: :outgoing,
          direct_address: i.even? }
      end

      signals = host.send(:extract_style_signals, 'partner-1', obs)
      expect(signals[:frequency_variance]).to be > 0.4
      expect(signals[:reciprocity_imbalance]).to be > 0.3
    end

    it 'actually drives derive_style! to :anxious with high-variance, high-imbalance signals' do
      model = Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentModel.new(agent_id: 'p')
      model.derive_style!(
        frequency_variance:    0.5,
        reciprocity_imbalance: 0.4,
        frequency:             0.6,
        direct_address_ratio:  0.3
      )
      expect(model.attachment_style).to eq(:anxious)
    end
  end

  describe '#build_narrative' do
    let(:model) do
      m = Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentModel.new(agent_id: 'p')
      m.instance_variable_set(:@bond_stage, :established)
      m.instance_variable_set(:@attachment_style, :secure)
      m
    end

    it 'returns nil when model is nil' do
      expect(host.send(:build_narrative, nil, 0.5, {})).to be_nil
    end

    it 'returns a non-empty string' do
      result = host.send(:build_narrative, model, 0.75, {})
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'includes stage and style' do
      result = host.send(:build_narrative, model, 0.75, {})
      expect(result).to include('established')
      expect(result).to include('secure')
    end

    it 'includes health value' do
      result = host.send(:build_narrative, model, 0.75, {})
      expect(result).to include('0.8') # format('%.1f', 0.75) => '0.8'
    end

    it 'includes chapter when present in arc_state' do
      result = host.send(:build_narrative, model, 0.5, { current_chapter: 'discovery' })
      expect(result).to include('discovery')
    end

    it 'includes milestone count when milestones present' do
      arc = { milestones_today: %w[first_conflict repair] }
      result = host.send(:build_narrative, model, 0.5, arc)
      expect(result).to include('2 milestone(s) today')
    end

    it 'does not include milestone text when milestones empty' do
      result = host.send(:build_narrative, model, 0.5, { milestones_today: [] })
      expect(result).not_to include('milestone')
    end
  end

  describe '#absence_exceeds_pattern?' do
    it 'returns false when agent_id is nil' do
      expect(host.send(:absence_exceeds_pattern?, nil)).to be false
    end

    it 'returns false when CommunicationPattern not defined and no apollo store' do
      allow(host).to receive(:apollo_local_store).and_return(nil)
      expect(host.send(:absence_exceeds_pattern?, 'partner-1')).to be false
    end

    it 'returns false when apollo store returns no results' do
      mock_store = double('apollo_local')
      allow(host).to receive(:apollo_local_store).and_return(mock_store)
      allow(mock_store).to receive(:query).and_return({ success: true, results: [] })
      expect(host.send(:absence_exceeds_pattern?, 'partner-1')).to be false
    end

    it 'returns false when apollo data has no avg_gap' do
      mock_store = double('apollo_local')
      allow(host).to receive(:apollo_local_store).and_return(mock_store)
      content = Legion::JSON.dump({ last_interaction_at: (Time.now - 3600).to_s })
      allow(mock_store).to receive(:query).and_return({
                                                        success: true,
                                                        results: [{ content: content }]
                                                      })
      expect(host.send(:absence_exceeds_pattern?, 'partner-1')).to be false
    end

    it 'returns true when current gap exceeds 2x average gap' do
      mock_store = double('apollo_local')
      allow(host).to receive(:apollo_local_store).and_return(mock_store)
      last_seen = Time.now - 7200 # 2 hours ago
      content = Legion::JSON.dump({
                                    average_gap_seconds: 1800.0, # normal = 30 min
                                    last_interaction_at: last_seen.to_s
                                  })
      allow(mock_store).to receive(:query).and_return({
                                                        success: true,
                                                        results: [{ content: content }]
                                                      })
      expect(host.send(:absence_exceeds_pattern?, 'partner-1')).to be true
    end

    it 'returns false when current gap is within normal range' do
      mock_store = double('apollo_local')
      allow(host).to receive(:apollo_local_store).and_return(mock_store)
      last_seen = Time.now - 600 # 10 minutes ago
      content = Legion::JSON.dump({
                                    average_gap_seconds: 1800.0, # normal = 30 min
                                    last_interaction_at: last_seen.to_s
                                  })
      allow(mock_store).to receive(:query).and_return({
                                                        success: true,
                                                        results: [{ content: content }]
                                                      })
      expect(host.send(:absence_exceeds_pattern?, 'partner-1')).to be false
    end
  end

  describe '#reflect_on_bonds — narrative and absence fields' do
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

    it 'includes a non-nil narrative in partner_bond' do
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(result[:partner_bond][:narrative]).not_to be_nil
      expect(result[:partner_bond][:narrative]).to be_a(String)
    end

    it 'includes absence_exceeds_pattern in partner_bond' do
      result = host.reflect_on_bonds(tick_results: {}, bond_summary: {})
      expect(result[:partner_bond]).to have_key(:absence_exceeds_pattern)
    end
  end
end
