# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants do
  describe 'MAX_EVENTS' do
    it 'equals 500' do
      expect(described_class::MAX_EVENTS).to eq(500)
    end
  end

  describe 'MAX_SIMULATIONS' do
    it 'equals 300' do
      expect(described_class::MAX_SIMULATIONS).to eq(300)
    end
  end

  describe 'DEFAULT_RESONANCE' do
    it 'equals 0.5' do
      expect(described_class::DEFAULT_RESONANCE).to eq(0.5)
    end
  end

  describe 'RESONANCE_BOOST' do
    it 'equals 0.1' do
      expect(described_class::RESONANCE_BOOST).to eq(0.1)
    end
  end

  describe 'RESONANCE_DECAY' do
    it 'equals 0.03' do
      expect(described_class::RESONANCE_DECAY).to eq(0.03)
    end
  end

  describe 'SIMULATION_CONFIDENCE_DEFAULT' do
    it 'equals 0.5' do
      expect(described_class::SIMULATION_CONFIDENCE_DEFAULT).to eq(0.5)
    end
  end

  describe 'ACTION_TYPES' do
    it 'contains exactly 8 types' do
      expect(described_class::ACTION_TYPES.size).to eq(8)
    end

    it 'includes all expected types' do
      expected = %i[movement communication decision emotional_expression
                    creative_act analytical_task social_interaction unknown]
      expect(described_class::ACTION_TYPES).to match_array(expected)
    end

    it 'is frozen' do
      expect(described_class::ACTION_TYPES).to be_frozen
    end
  end

  describe 'RESONANCE_LABELS' do
    it 'maps low values to :minimal' do
      expect(described_class::RESONANCE_LABELS[(0.0..0.2)]).to eq(:minimal)
    end

    it 'maps high values to :deep' do
      expect(described_class::RESONANCE_LABELS[(0.8..1.0)]).to eq(:deep)
    end
  end

  describe 'CONFIDENCE_LABELS' do
    it 'maps low values to :uncertain' do
      expect(described_class::CONFIDENCE_LABELS[(0.0..0.2)]).to eq(:uncertain)
    end

    it 'maps high values to :certain' do
      expect(described_class::CONFIDENCE_LABELS[(0.8..1.0)]).to eq(:certain)
    end
  end

  describe 'EMPATHY_LABELS' do
    it 'maps low values to :detached' do
      expect(described_class::EMPATHY_LABELS[(0.0..0.2)]).to eq(:detached)
    end

    it 'maps high values to :immersed' do
      expect(described_class::EMPATHY_LABELS[(0.8..1.0)]).to eq(:immersed)
    end
  end

  describe '.label_for' do
    it 'returns :minimal for 0.1' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 0.1)).to eq(:minimal)
    end

    it 'returns :low for 0.3' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 0.3)).to eq(:low)
    end

    it 'returns :moderate for 0.5' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 0.5)).to eq(:moderate)
    end

    it 'returns :high for 0.7' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 0.7)).to eq(:high)
    end

    it 'returns :deep for 0.9' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 0.9)).to eq(:deep)
    end

    it 'clamps values above 1.0' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, 1.5)).to eq(:deep)
    end

    it 'clamps values below 0.0' do
      expect(described_class.label_for(described_class::RESONANCE_LABELS, -0.5)).to eq(:minimal)
    end

    it 'works with CONFIDENCE_LABELS' do
      expect(described_class.label_for(described_class::CONFIDENCE_LABELS, 0.75)).to eq(:confident)
    end

    it 'works with EMPATHY_LABELS' do
      expect(described_class.label_for(described_class::EMPATHY_LABELS, 0.65)).to eq(:resonant)
    end
  end
end
