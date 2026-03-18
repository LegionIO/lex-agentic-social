# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Conflict::Helpers::Severity do
  describe 'LEVELS' do
    it 'is a frozen array of symbols' do
      expect(described_class::LEVELS).to be_a(Array)
      expect(described_class::LEVELS).to be_frozen
    end

    it 'contains exactly four levels' do
      expect(described_class::LEVELS.size).to eq(4)
    end

    it 'includes :low' do
      expect(described_class::LEVELS).to include(:low)
    end

    it 'includes :medium' do
      expect(described_class::LEVELS).to include(:medium)
    end

    it 'includes :high' do
      expect(described_class::LEVELS).to include(:high)
    end

    it 'includes :critical' do
      expect(described_class::LEVELS).to include(:critical)
    end

    it 'is ordered from least to most severe' do
      expect(described_class::LEVELS).to eq(%i[low medium high critical])
    end
  end

  describe 'POSTURES' do
    it 'is a frozen array of symbols' do
      expect(described_class::POSTURES).to be_a(Array)
      expect(described_class::POSTURES).to be_frozen
    end

    it 'contains exactly three postures' do
      expect(described_class::POSTURES.size).to eq(3)
    end

    it 'includes :speak_once' do
      expect(described_class::POSTURES).to include(:speak_once)
    end

    it 'includes :persistent_engagement' do
      expect(described_class::POSTURES).to include(:persistent_engagement)
    end

    it 'includes :stubborn_presence' do
      expect(described_class::POSTURES).to include(:stubborn_presence)
    end
  end

  describe 'LEVEL_ORDER' do
    it 'is a frozen hash' do
      expect(described_class::LEVEL_ORDER).to be_a(Hash)
      expect(described_class::LEVEL_ORDER).to be_frozen
    end

    it 'assigns :low the lowest numeric value' do
      expect(described_class::LEVEL_ORDER[:low]).to eq(0)
    end

    it 'assigns :medium a higher value than :low' do
      expect(described_class::LEVEL_ORDER[:medium]).to be > described_class::LEVEL_ORDER[:low]
    end

    it 'assigns :high a higher value than :medium' do
      expect(described_class::LEVEL_ORDER[:high]).to be > described_class::LEVEL_ORDER[:medium]
    end

    it 'assigns :critical the highest numeric value' do
      expect(described_class::LEVEL_ORDER[:critical]).to be > described_class::LEVEL_ORDER[:high]
    end

    it 'covers all LEVELS' do
      described_class::LEVELS.each do |level|
        expect(described_class::LEVEL_ORDER).to have_key(level)
      end
    end
  end

  describe '.valid_level?' do
    it 'returns true for :low' do
      expect(described_class.valid_level?(:low)).to be true
    end

    it 'returns true for :medium' do
      expect(described_class.valid_level?(:medium)).to be true
    end

    it 'returns true for :high' do
      expect(described_class.valid_level?(:high)).to be true
    end

    it 'returns true for :critical' do
      expect(described_class.valid_level?(:critical)).to be true
    end

    it 'returns false for an unknown symbol' do
      expect(described_class.valid_level?(:catastrophic)).to be false
    end

    it 'returns false for a string form of a valid level' do
      expect(described_class.valid_level?('high')).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_level?(nil)).to be false
    end

    it 'returns true for every member of LEVELS' do
      described_class::LEVELS.each do |level|
        expect(described_class.valid_level?(level)).to be true
      end
    end
  end

  describe '.valid_posture?' do
    it 'returns true for :speak_once' do
      expect(described_class.valid_posture?(:speak_once)).to be true
    end

    it 'returns true for :persistent_engagement' do
      expect(described_class.valid_posture?(:persistent_engagement)).to be true
    end

    it 'returns true for :stubborn_presence' do
      expect(described_class.valid_posture?(:stubborn_presence)).to be true
    end

    it 'returns false for an unknown posture symbol' do
      expect(described_class.valid_posture?(:passive)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_posture?(nil)).to be false
    end

    it 'returns true for every member of POSTURES' do
      described_class::POSTURES.each do |posture|
        expect(described_class.valid_posture?(posture)).to be true
      end
    end
  end

  describe '.recommended_posture' do
    it 'returns :stubborn_presence for :critical' do
      expect(described_class.recommended_posture(:critical)).to eq(:stubborn_presence)
    end

    it 'returns :persistent_engagement for :high' do
      expect(described_class.recommended_posture(:high)).to eq(:persistent_engagement)
    end

    it 'returns :speak_once for :medium' do
      expect(described_class.recommended_posture(:medium)).to eq(:speak_once)
    end

    it 'returns :speak_once for :low' do
      expect(described_class.recommended_posture(:low)).to eq(:speak_once)
    end

    it 'returns :speak_once for an unrecognized severity' do
      expect(described_class.recommended_posture(:unknown)).to eq(:speak_once)
    end

    it 'returns a posture that is a member of POSTURES for every valid level' do
      described_class::LEVELS.each do |level|
        posture = described_class.recommended_posture(level)
        expect(described_class::POSTURES).to include(posture)
      end
    end
  end

  describe '.severity_gte?' do
    it 'returns true when left equals right' do
      expect(described_class.severity_gte?(:medium, :medium)).to be true
    end

    it 'returns true when left is strictly greater' do
      expect(described_class.severity_gte?(:high, :medium)).to be true
    end

    it 'returns false when left is strictly less' do
      expect(described_class.severity_gte?(:low, :medium)).to be false
    end

    it ':critical >= :high is true' do
      expect(described_class.severity_gte?(:critical, :high)).to be true
    end

    it ':critical >= :critical is true' do
      expect(described_class.severity_gte?(:critical, :critical)).to be true
    end

    it ':low >= :critical is false' do
      expect(described_class.severity_gte?(:low, :critical)).to be false
    end

    it 'treats an unknown left level as order 0 (same as :low)' do
      expect(described_class.severity_gte?(:unknown, :medium)).to be false
    end

    it 'treats an unknown right level as order 0, so any valid level >= it' do
      expect(described_class.severity_gte?(:low, :unknown)).to be true
    end
  end
end
