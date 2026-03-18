# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::Constants do
  describe 'constants' do
    it 'defines MAX_PERSPECTIVES' do
      expect(described_class::MAX_PERSPECTIVES).to eq(50)
    end

    it 'defines MAX_SITUATIONS' do
      expect(described_class::MAX_SITUATIONS).to eq(200)
    end

    it 'defines MAX_VIEWS_PER_SITUATION' do
      expect(described_class::MAX_VIEWS_PER_SITUATION).to eq(20)
    end

    it 'defines DEFAULT_EMPATHY' do
      expect(described_class::DEFAULT_EMPATHY).to eq(0.5)
    end

    it 'defines MIN_PERSPECTIVES_FOR_SYNTHESIS' do
      expect(described_class::MIN_PERSPECTIVES_FOR_SYNTHESIS).to eq(2)
    end

    it 'defines all perspective types' do
      expect(described_class::PERSPECTIVE_TYPES).to include(:stakeholder, :ethical, :temporal, :cultural)
    end

    it 'defines all priority types' do
      expect(described_class::PRIORITY_TYPES).to include(:safety, :efficiency, :fairness, :innovation)
    end
  end

  describe '.empathy_label' do
    it 'returns :deeply_empathic for 0.9' do
      expect(described_class.empathy_label(0.9)).to eq(:deeply_empathic)
    end

    it 'returns :empathic for 0.7' do
      expect(described_class.empathy_label(0.7)).to eq(:empathic)
    end

    it 'returns :moderate for 0.5' do
      expect(described_class.empathy_label(0.5)).to eq(:moderate)
    end

    it 'returns :limited for 0.3' do
      expect(described_class.empathy_label(0.3)).to eq(:limited)
    end

    it 'returns :detached for 0.1' do
      expect(described_class.empathy_label(0.1)).to eq(:detached)
    end
  end

  describe '.coverage_label' do
    it 'returns :comprehensive for 0.9' do
      expect(described_class.coverage_label(0.9)).to eq(:comprehensive)
    end

    it 'returns :thorough for 0.7' do
      expect(described_class.coverage_label(0.7)).to eq(:thorough)
    end

    it 'returns :partial for 0.5' do
      expect(described_class.coverage_label(0.5)).to eq(:partial)
    end

    it 'returns :narrow for 0.3' do
      expect(described_class.coverage_label(0.3)).to eq(:narrow)
    end

    it 'returns :blind for 0.1' do
      expect(described_class.coverage_label(0.1)).to eq(:blind)
    end
  end

  describe '.agreement_label' do
    it 'returns :consensus for 0.9' do
      expect(described_class.agreement_label(0.9)).to eq(:consensus)
    end

    it 'returns :agreement for 0.7' do
      expect(described_class.agreement_label(0.7)).to eq(:agreement)
    end

    it 'returns :mixed for 0.5' do
      expect(described_class.agreement_label(0.5)).to eq(:mixed)
    end

    it 'returns :disagreement for 0.3' do
      expect(described_class.agreement_label(0.3)).to eq(:disagreement)
    end

    it 'returns :conflict for 0.1' do
      expect(described_class.agreement_label(0.1)).to eq(:conflict)
    end
  end
end
