# frozen_string_literal: true

require 'legion/extensions/agentic/social/governance/helpers/layers'

RSpec.describe Legion::Extensions::Agentic::Social::Governance::Helpers::Layers do
  describe 'GOVERNANCE_LAYERS' do
    it 'contains four layers as symbols' do
      expect(described_class::GOVERNANCE_LAYERS.size).to eq(4)
    end

    it 'includes agent_validation' do
      expect(described_class::GOVERNANCE_LAYERS).to include(:agent_validation)
    end

    it 'includes anomaly_detection' do
      expect(described_class::GOVERNANCE_LAYERS).to include(:anomaly_detection)
    end

    it 'includes human_deliberation' do
      expect(described_class::GOVERNANCE_LAYERS).to include(:human_deliberation)
    end

    it 'includes transparency' do
      expect(described_class::GOVERNANCE_LAYERS).to include(:transparency)
    end

    it 'is frozen' do
      expect(described_class::GOVERNANCE_LAYERS).to be_frozen
    end
  end

  describe 'PROPOSAL_CATEGORIES' do
    it 'contains five categories' do
      expect(described_class::PROPOSAL_CATEGORIES.size).to eq(5)
    end

    it 'includes policy_change' do
      expect(described_class::PROPOSAL_CATEGORIES).to include(:policy_change)
    end

    it 'includes resource_allocation' do
      expect(described_class::PROPOSAL_CATEGORIES).to include(:resource_allocation)
    end

    it 'includes access_control' do
      expect(described_class::PROPOSAL_CATEGORIES).to include(:access_control)
    end

    it 'includes emergency' do
      expect(described_class::PROPOSAL_CATEGORIES).to include(:emergency)
    end

    it 'includes protocol_update' do
      expect(described_class::PROPOSAL_CATEGORIES).to include(:protocol_update)
    end

    it 'is frozen' do
      expect(described_class::PROPOSAL_CATEGORIES).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'sets MIN_COUNCIL_SIZE to 3' do
      expect(described_class::MIN_COUNCIL_SIZE).to eq(3)
    end

    it 'sets QUORUM_FRACTION to 0.66' do
      expect(described_class::QUORUM_FRACTION).to eq(0.66)
    end

    it 'sets VOTE_TIMEOUT to 86400' do
      expect(described_class::VOTE_TIMEOUT).to eq(86_400)
    end
  end

  describe '.valid_layer?' do
    it 'returns true for agent_validation' do
      expect(described_class.valid_layer?(:agent_validation)).to be true
    end

    it 'returns true for anomaly_detection' do
      expect(described_class.valid_layer?(:anomaly_detection)).to be true
    end

    it 'returns true for human_deliberation' do
      expect(described_class.valid_layer?(:human_deliberation)).to be true
    end

    it 'returns true for transparency' do
      expect(described_class.valid_layer?(:transparency)).to be true
    end

    it 'returns false for unknown layer symbol' do
      expect(described_class.valid_layer?(:unknown)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_layer?(nil)).to be false
    end

    it 'returns false for string version of valid layer' do
      expect(described_class.valid_layer?('agent_validation')).to be false
    end
  end

  describe '.valid_category?' do
    it 'returns true for policy_change' do
      expect(described_class.valid_category?(:policy_change)).to be true
    end

    it 'returns true for resource_allocation' do
      expect(described_class.valid_category?(:resource_allocation)).to be true
    end

    it 'returns true for access_control' do
      expect(described_class.valid_category?(:access_control)).to be true
    end

    it 'returns true for emergency' do
      expect(described_class.valid_category?(:emergency)).to be true
    end

    it 'returns true for protocol_update' do
      expect(described_class.valid_category?(:protocol_update)).to be true
    end

    it 'returns false for unknown category' do
      expect(described_class.valid_category?(:invalid)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_category?(nil)).to be false
    end

    it 'returns false for string version of valid category' do
      expect(described_class.valid_category?('emergency')).to be false
    end
  end

  describe '.quorum_met?' do
    context 'when council_size is below minimum' do
      it 'returns false for council_size of 2' do
        expect(described_class.quorum_met?(2, 2)).to be false
      end

      it 'returns false for council_size of 1' do
        expect(described_class.quorum_met?(1, 1)).to be false
      end

      it 'returns false for council_size of 0' do
        expect(described_class.quorum_met?(0, 0)).to be false
      end
    end

    context 'with minimum council size of 3' do
      it 'returns true when 2 of 3 vote (meets ceil(3 * 0.66) = 2)' do
        expect(described_class.quorum_met?(2, 3)).to be true
      end

      it 'returns true when all 3 vote' do
        expect(described_class.quorum_met?(3, 3)).to be true
      end

      it 'returns false when only 1 of 3 vote' do
        expect(described_class.quorum_met?(1, 3)).to be false
      end
    end

    context 'with larger council sizes' do
      it 'requires ceil(4 * 0.66) = 3 votes for council of 4' do
        expect(described_class.quorum_met?(3, 4)).to be true
        expect(described_class.quorum_met?(2, 4)).to be false
      end

      it 'requires ceil(5 * 0.66) = 4 votes for council of 5' do
        expect(described_class.quorum_met?(4, 5)).to be true
        expect(described_class.quorum_met?(3, 5)).to be false
      end

      it 'requires ceil(9 * 0.66) = 6 votes for council of 9' do
        expect(described_class.quorum_met?(6, 9)).to be true
        expect(described_class.quorum_met?(5, 9)).to be false
      end
    end

    it 'returns false for zero votes regardless of council size' do
      expect(described_class.quorum_met?(0, 3)).to be false
    end
  end
end
