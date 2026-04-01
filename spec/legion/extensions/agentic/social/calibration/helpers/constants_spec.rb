# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Calibration::Helpers::Constants do
  describe 'ADVISORY_TYPES' do
    it 'defines five advisory types' do
      expect(described_class::ADVISORY_TYPES.size).to eq(5)
    end

    it 'contains expected types' do
      expect(described_class::ADVISORY_TYPES).to include(:tone_adjustment, :verbosity_adjustment)
    end
  end

  describe '.advisory_type?' do
    it 'returns true for valid types' do
      expect(described_class.advisory_type?(:tone_adjustment)).to be true
    end

    it 'returns false for invalid types' do
      expect(described_class.advisory_type?(:bogus)).to be false
    end

    it 'accepts string conversion' do
      expect(described_class.advisory_type?('partner_hint')).to be true
    end
  end

  describe '.suppressed?' do
    it 'returns true below threshold' do
      expect(described_class.suppressed?(0.3)).to be true
    end

    it 'returns false at or above threshold' do
      expect(described_class.suppressed?(0.4)).to be false
      expect(described_class.suppressed?(0.7)).to be false
    end
  end

  describe 'SIGNAL_WEIGHTS' do
    it 'sums to 1.0' do
      expect(described_class::SIGNAL_WEIGHTS.values.sum).to be_within(0.001).of(1.0)
    end
  end

  describe 'TAG constants' do
    it 'has correct weights tags' do
      expect(described_class::WEIGHTS_TAGS).to eq(%w[bond calibration weights])
    end

    it 'has correct history tag prefix' do
      expect(described_class::HISTORY_TAG_PREFIX).to eq(%w[bond calibration history])
    end
  end
end
