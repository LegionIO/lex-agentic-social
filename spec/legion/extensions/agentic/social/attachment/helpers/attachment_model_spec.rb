# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/social/attachment/helpers/constants'
require 'legion/extensions/agentic/social/attachment/helpers/attachment_model'

RSpec.describe Legion::Extensions::Agentic::Social::Attachment::Helpers::AttachmentModel do
  subject(:model) { described_class.new(agent_id: 'partner-1') }

  describe '#initialize' do
    it 'sets agent_id' do
      expect(model.agent_id).to eq('partner-1')
    end

    it 'starts at initial stage' do
      expect(model.bond_stage).to eq(:initial)
    end

    it 'starts with zero strength' do
      expect(model.attachment_strength).to eq(0.0)
    end

    it 'starts with secure style' do
      expect(model.attachment_style).to eq(:secure)
    end

    it 'starts with base separation tolerance' do
      expect(model.separation_tolerance).to eq(3)
    end

    it 'starts with zero interaction count' do
      expect(model.interaction_count).to eq(0)
    end
  end

  describe '#update_from_signals' do
    let(:signals) do
      {
        frequency_score: 0.6,
        reciprocity_score: 0.5,
        prediction_accuracy: 0.7,
        direct_address_ratio: 0.4,
        channel_consistency: 0.8
      }
    end

    it 'computes attachment strength from weighted signals' do
      model.update_from_signals(signals)
      expected = (0.6 * 0.3) + (0.5 * 0.25) + (0.7 * 0.2) + (0.4 * 0.15) + (0.8 * 0.1)
      expect(model.attachment_strength).to be_within(0.01).of(expected)
    end

    it 'increments interaction count' do
      model.update_from_signals(signals)
      expect(model.interaction_count).to eq(1)
    end

    it 'uses EMA for subsequent updates' do
      model.update_from_signals(signals)
      first_strength = model.attachment_strength
      model.update_from_signals(signals.merge(frequency_score: 1.0))
      expect(model.attachment_strength).not_to eq(first_strength)
    end
  end

  describe '#update_stage!' do
    it 'transitions to forming at 10 interactions and strength > 0.3' do
      model.instance_variable_set(:@interaction_count, 10)
      model.instance_variable_set(:@attachment_strength, 0.35)
      model.update_stage!
      expect(model.bond_stage).to eq(:forming)
    end

    it 'transitions to established at 50 interactions and strength > 0.5' do
      model.instance_variable_set(:@interaction_count, 50)
      model.instance_variable_set(:@attachment_strength, 0.55)
      model.instance_variable_set(:@bond_stage, :forming)
      model.update_stage!
      expect(model.bond_stage).to eq(:established)
    end

    it 'transitions to deep at 200 interactions and strength > 0.7' do
      model.instance_variable_set(:@interaction_count, 200)
      model.instance_variable_set(:@attachment_strength, 0.75)
      model.instance_variable_set(:@bond_stage, :established)
      model.update_stage!
      expect(model.bond_stage).to eq(:deep)
    end

    it 'never regresses stages' do
      model.instance_variable_set(:@bond_stage, :established)
      model.instance_variable_set(:@interaction_count, 5)
      model.instance_variable_set(:@attachment_strength, 0.1)
      model.update_stage!
      expect(model.bond_stage).to eq(:established)
    end

    it 'updates separation tolerance on stage change' do
      model.instance_variable_set(:@interaction_count, 50)
      model.instance_variable_set(:@attachment_strength, 0.55)
      model.instance_variable_set(:@bond_stage, :forming)
      model.update_stage!
      expect(model.separation_tolerance).to eq(3 + 2)
    end
  end

  describe '#derive_style!' do
    it 'defaults to secure' do
      model.derive_style!(frequency_variance: 0.1, reciprocity_imbalance: 0.1,
                          frequency: 0.5, direct_address_ratio: 0.5)
      expect(model.attachment_style).to eq(:secure)
    end

    it 'detects anxious from high variance and imbalance' do
      model.derive_style!(frequency_variance: 0.5, reciprocity_imbalance: 0.4,
                          frequency: 0.5, direct_address_ratio: 0.5)
      expect(model.attachment_style).to eq(:anxious)
    end

    it 'detects avoidant from low frequency and low direct address' do
      model.derive_style!(frequency_variance: 0.1, reciprocity_imbalance: 0.1,
                          frequency: 0.1, direct_address_ratio: 0.1)
      expect(model.attachment_style).to eq(:avoidant)
    end
  end

  describe '#to_h' do
    it 'returns a complete hash' do
      h = model.to_h
      expect(h).to include(:agent_id, :attachment_strength, :attachment_style,
                           :bond_stage, :separation_tolerance, :interaction_count)
    end
  end

  describe 'serialization' do
    it 'round-trips through from_h' do
      model.instance_variable_set(:@attachment_strength, 0.65)
      model.instance_variable_set(:@bond_stage, :established)
      model.instance_variable_set(:@interaction_count, 55)
      restored = described_class.from_h(model.to_h)
      expect(restored.to_h).to eq(model.to_h)
    end
  end
end
