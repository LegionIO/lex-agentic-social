# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::Perspective do
  let(:perspective) do
    described_class.new(
      name:              'CEO',
      perspective_type:  :stakeholder,
      priorities:        %i[growth stability],
      expertise_domains: %w[business strategy],
      empathy_level:     0.7,
      bias_toward:       :profit
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(perspective.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns name' do
      expect(perspective.name).to eq('CEO')
    end

    it 'assigns perspective_type' do
      expect(perspective.perspective_type).to eq(:stakeholder)
    end

    it 'assigns priorities' do
      expect(perspective.priorities).to eq(%i[growth stability])
    end

    it 'assigns expertise_domains' do
      expect(perspective.expertise_domains).to eq(%w[business strategy])
    end

    it 'clamps empathy_level between 0 and 1' do
      p = described_class.new(name: 'x', perspective_type: :ethical, empathy_level: 1.5)
      expect(p.empathy_level).to eq(1.0)
    end

    it 'clamps empathy_level at 0' do
      p = described_class.new(name: 'x', perspective_type: :ethical, empathy_level: -0.5)
      expect(p.empathy_level).to eq(0.0)
    end

    it 'assigns bias_toward' do
      expect(perspective.bias_toward).to eq(:profit)
    end

    it 'assigns created_at as UTC time' do
      expect(perspective.created_at).to be_a(Time)
    end

    it 'defaults priorities to empty array' do
      p = described_class.new(name: 'x', perspective_type: :ethical)
      expect(p.priorities).to eq([])
    end

    it 'defaults expertise_domains to empty array' do
      p = described_class.new(name: 'x', perspective_type: :ethical)
      expect(p.expertise_domains).to eq([])
    end
  end

  describe '#to_h' do
    subject(:hash) { perspective.to_h }

    it 'includes all keys' do
      expect(hash.keys).to include(:id, :name, :perspective_type, :priorities,
                                   :expertise_domains, :empathy_level, :bias_toward, :created_at)
    end

    it 'rounds empathy_level to 10 decimal places' do
      expect(hash[:empathy_level]).to eq(0.7.round(10))
    end
  end
end
