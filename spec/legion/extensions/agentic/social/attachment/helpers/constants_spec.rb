# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/social/attachment/helpers/constants'

RSpec.describe Legion::Extensions::Agentic::Social::Attachment::Helpers::Constants do
  describe 'strength weights' do
    it 'sums to 1.0' do
      sum = described_class::FREQUENCY_WEIGHT +
            described_class::RECIPROCITY_WEIGHT +
            described_class::PREDICTION_ACCURACY_WEIGHT +
            described_class::DIRECT_ADDRESS_WEIGHT +
            described_class::CHANNEL_CONSISTENCY_WEIGHT
      expect(sum).to eq(1.0)
    end
  end

  describe 'BOND_STAGES' do
    it 'defines 4 stages in order' do
      expect(described_class::BOND_STAGES).to eq(%i[initial forming established deep])
    end
  end

  describe 'ATTACHMENT_STYLES' do
    it 'defines 3 styles' do
      expect(described_class::ATTACHMENT_STYLES).to eq(%i[secure anxious avoidant])
    end
  end

  describe 'stage thresholds' do
    it 'has forming thresholds' do
      expect(described_class::STAGE_THRESHOLDS[:forming]).to eq({ interactions: 10, strength: 0.3 })
    end

    it 'has established thresholds' do
      expect(described_class::STAGE_THRESHOLDS[:established]).to eq({ interactions: 50, strength: 0.5 })
    end

    it 'has deep thresholds' do
      expect(described_class::STAGE_THRESHOLDS[:deep]).to eq({ interactions: 200, strength: 0.7 })
    end
  end

  describe 'SEPARATION_TOLERANCE' do
    it 'starts at 3' do
      expect(described_class::BASE_SEPARATION_TOLERANCE).to eq(3)
    end

    it 'grows with stage' do
      expect(described_class::SEPARATION_TOLERANCE_GROWTH[:deep]).to be > described_class::SEPARATION_TOLERANCE_GROWTH[:initial]
    end
  end
end
