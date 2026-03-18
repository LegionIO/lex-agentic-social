# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Symbiosis::Helpers::Constants do
  describe 'RELATIONSHIP_TYPES' do
    it 'contains the three canonical types' do
      expect(described_class::RELATIONSHIP_TYPES).to contain_exactly(:mutualistic, :parasitic, :commensal)
    end

    it 'is frozen' do
      expect(described_class::RELATIONSHIP_TYPES).to be_frozen
    end
  end

  describe 'INTERACTION_STRENGTHS' do
    it 'maps range 0.0..0.2 to :dormant' do
      label = described_class::INTERACTION_STRENGTHS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:dormant)
    end

    it 'maps range 0.6..0.8 to :strong' do
      label = described_class::INTERACTION_STRENGTHS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:strong)
    end

    it 'maps range 0.8..1.0 to :dominant' do
      label = described_class::INTERACTION_STRENGTHS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:dominant)
    end
  end

  describe 'MAX_BONDS' do
    it 'is 200' do
      expect(described_class::MAX_BONDS).to eq(200)
    end
  end

  describe 'BOND_DECAY' do
    it 'is a positive float' do
      expect(described_class::BOND_DECAY).to be > 0
      expect(described_class::BOND_DECAY).to be < 1
    end
  end

  describe 'BENEFIT_RATIO_RANGES' do
    it 'has positive range for mutualistic' do
      range = described_class::BENEFIT_RATIO_RANGES[:mutualistic]
      expect(range.min).to be > 0
    end

    it 'has negative range for parasitic' do
      range = described_class::BENEFIT_RATIO_RANGES[:parasitic]
      expect(range.max).to be < 0
    end

    it 'has near-zero range for commensal' do
      range = described_class::BENEFIT_RATIO_RANGES[:commensal]
      expect(range.min.abs).to be < 0.1
      expect(range.max.abs).to be < 0.1
    end
  end

  describe 'ECOSYSTEM_HEALTH_LABELS' do
    it 'maps 0.0..0.2 to :critical' do
      label = described_class::ECOSYSTEM_HEALTH_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:critical)
    end

    it 'maps 0.8..1.0 to :flourishing' do
      label = described_class::ECOSYSTEM_HEALTH_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:flourishing)
    end
  end
end
