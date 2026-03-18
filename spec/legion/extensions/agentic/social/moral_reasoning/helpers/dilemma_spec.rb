# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Helpers::Dilemma do
  let(:options) do
    [
      { id: 'opt_a', description: 'Help the many', foundations: %i[care fairness] },
      { id: 'opt_b', description: 'Follow the rule', foundations: %i[authority loyalty] }
    ]
  end

  subject(:dilemma) do
    described_class.new(
      id:          'dilemma_1',
      description: 'A trolley problem',
      options:     options,
      domain:      :ethics,
      severity:    0.9
    )
  end

  describe '#initialize' do
    it 'sets id, description, domain, severity' do
      expect(dilemma.id).to eq('dilemma_1')
      expect(dilemma.description).to eq('A trolley problem')
      expect(dilemma.domain).to eq(:ethics)
      expect(dilemma.severity).to eq(0.9)
    end

    it 'is not resolved by default' do
      expect(dilemma.resolved?).to be false
    end

    it 'has nil chosen_option, reasoning, framework_used' do
      expect(dilemma.chosen_option).to be_nil
      expect(dilemma.reasoning).to be_nil
      expect(dilemma.framework_used).to be_nil
    end

    it 'clamps severity above 1.0' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: 1.5)
      expect(d.severity).to eq(1.0)
    end

    it 'clamps severity below 0.0' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: -0.5)
      expect(d.severity).to eq(0.0)
    end
  end

  describe '#severity_label' do
    it 'returns :critical for severity >= 0.8' do
      expect(dilemma.severity_label).to eq(:critical)
    end

    it 'returns :serious for severity 0.6..0.79' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: 0.7)
      expect(d.severity_label).to eq(:serious)
    end

    it 'returns :moderate for severity 0.4..0.59' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: 0.5)
      expect(d.severity_label).to eq(:moderate)
    end

    it 'returns :minor for severity 0.2..0.39' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: 0.3)
      expect(d.severity_label).to eq(:minor)
    end

    it 'returns :trivial for severity < 0.2' do
      d = described_class.new(id: 'x', description: 'x', options: [], severity: 0.1)
      expect(d.severity_label).to eq(:trivial)
    end
  end

  describe '#resolve' do
    before { dilemma.resolve(option_id: 'opt_a', reasoning: 'Utilitarian outcome', framework: :utilitarian) }

    it 'marks dilemma as resolved' do
      expect(dilemma.resolved?).to be true
    end

    it 'sets chosen_option' do
      expect(dilemma.chosen_option).to eq('opt_a')
    end

    it 'sets reasoning' do
      expect(dilemma.reasoning).to eq('Utilitarian outcome')
    end

    it 'sets framework_used' do
      expect(dilemma.framework_used).to eq(:utilitarian)
    end

    it 'sets resolved_at timestamp' do
      expect(dilemma.resolved_at).not_to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = dilemma.to_h
      expect(h).to include(:id, :description, :domain, :severity, :severity_label,
                           :options, :chosen_option, :reasoning, :framework_used,
                           :resolved, :created_at, :resolved_at)
    end
  end
end
