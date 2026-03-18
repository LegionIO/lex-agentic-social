# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::PerspectiveView do
  let(:view) do
    described_class.new(
      situation_id:   'sit-123',
      perspective_id: 'persp-456',
      valence:        0.6,
      concerns:       ['risk of failure'],
      opportunities:  ['cost savings'],
      confidence:     0.8
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(view.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns situation_id' do
      expect(view.situation_id).to eq('sit-123')
    end

    it 'assigns perspective_id' do
      expect(view.perspective_id).to eq('persp-456')
    end

    it 'clamps valence to -1..1' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', valence: 2.0)
      expect(v.valence).to eq(1.0)
    end

    it 'clamps valence at -1' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', valence: -3.0)
      expect(v.valence).to eq(-1.0)
    end

    it 'clamps confidence to 0..1' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', confidence: 1.5)
      expect(v.confidence).to eq(1.0)
    end

    it 'assigns concerns array' do
      expect(view.concerns).to eq(['risk of failure'])
    end

    it 'assigns opportunities array' do
      expect(view.opportunities).to eq(['cost savings'])
    end

    it 'assigns created_at' do
      expect(view.created_at).to be_a(Time)
    end
  end

  describe '#positive?' do
    it 'returns true when valence > 0.1' do
      expect(view.positive?).to be true
    end

    it 'returns false for neutral valence' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', valence: 0.0)
      expect(v.positive?).to be false
    end
  end

  describe '#negative?' do
    it 'returns true when valence < -0.1' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', valence: -0.5)
      expect(v.negative?).to be true
    end

    it 'returns false for positive valence' do
      expect(view.negative?).to be false
    end
  end

  describe '#neutral?' do
    it 'returns true when valence is near 0' do
      v = described_class.new(situation_id: 's', perspective_id: 'p', valence: 0.05)
      expect(v.neutral?).to be true
    end

    it 'returns false when clearly positive' do
      expect(view.neutral?).to be false
    end
  end

  describe '#to_h' do
    subject(:hash) { view.to_h }

    it 'includes all keys' do
      expect(hash.keys).to include(:id, :situation_id, :perspective_id, :valence,
                                   :concerns, :opportunities, :confidence, :created_at)
    end

    it 'rounds valence to 10 decimal places' do
      expect(hash[:valence]).to eq(0.6.round(10))
    end

    it 'rounds confidence to 10 decimal places' do
      expect(hash[:confidence]).to eq(0.8.round(10))
    end
  end
end
