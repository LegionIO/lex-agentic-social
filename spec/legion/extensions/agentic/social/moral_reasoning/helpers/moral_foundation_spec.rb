# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::MoralFoundation do
  subject(:foundation) { described_class.new(id: :care) }

  describe '#initialize' do
    it 'sets id' do
      expect(foundation.id).to eq(:care)
    end

    it 'defaults weight to DEFAULT_WEIGHT' do
      expect(foundation.weight).to eq(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::DEFAULT_WEIGHT)
    end

    it 'clamps weight to WEIGHT_FLOOR if below floor' do
      f = described_class.new(id: :care, weight: 0.0)
      expect(f.weight).to eq(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_FLOOR)
    end

    it 'clamps weight to WEIGHT_CEILING if above ceiling' do
      f = described_class.new(id: :care, weight: 2.0)
      expect(f.weight).to eq(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_CEILING)
    end
  end

  describe '#reinforce' do
    it 'increases weight' do
      before = foundation.weight
      foundation.reinforce(amount: 1.0)
      expect(foundation.weight).to be > before
    end

    it 'does not exceed WEIGHT_CEILING' do
      10.times { foundation.reinforce(amount: 10.0) }
      expect(foundation.weight).to eq(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_CEILING)
    end
  end

  describe '#weaken' do
    it 'decreases weight' do
      before = foundation.weight
      foundation.weaken(amount: 1.0)
      expect(foundation.weight).to be < before
    end

    it 'does not go below WEIGHT_FLOOR' do
      10.times { foundation.weaken(amount: 10.0) }
      expect(foundation.weight).to eq(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_FLOOR)
    end
  end

  describe '#decay' do
    it 'decreases weight by DECAY_RATE' do
      before = foundation.weight
      foundation.decay
      expected = (before - Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::DECAY_RATE)
                 .clamp(Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_FLOOR,
                        Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Constants::WEIGHT_CEILING)
      expect(foundation.weight).to eq(expected)
    end
  end

  describe '#to_h' do
    it 'returns a hash with id, weight, sensitivity' do
      h = foundation.to_h
      expect(h).to include(:id, :weight, :sensitivity)
      expect(h[:id]).to eq(:care)
    end
  end
end
