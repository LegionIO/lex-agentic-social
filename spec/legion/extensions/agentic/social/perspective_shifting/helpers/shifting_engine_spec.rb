# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::ShiftingEngine do
  subject(:engine) { described_class.new }

  let(:ceo_id) do
    engine.add_perspective(name: 'CEO', type: :stakeholder, priorities: %i[growth], empathy: 0.6).id
  end

  let(:engineer_id) do
    engine.add_perspective(name: 'Engineer', type: :pragmatic, priorities: %i[stability], empathy: 0.7).id
  end

  let(:ethicist_id) do
    engine.add_perspective(name: 'Ethicist', type: :ethical, priorities: %i[fairness], empathy: 0.9).id
  end

  let(:situation_id) do
    engine.add_situation(content: 'Deploy AI hiring tool')[:id]
  end

  describe '#add_perspective' do
    it 'creates a perspective and stores it' do
      p = engine.add_perspective(name: 'Manager', type: :stakeholder)
      expect(engine.perspectives[p.id]).to eq(p)
    end

    it 'returns error for invalid type' do
      result = engine.add_perspective(name: 'x', type: :unknown)
      expect(result[:error]).to eq(:invalid_type)
    end

    it 'returns error when at capacity' do
      50.times { |i| engine.add_perspective(name: "p#{i}", type: :stakeholder) }
      result = engine.add_perspective(name: 'overflow', type: :stakeholder)
      expect(result[:error]).to eq(:too_many_perspectives)
    end
  end

  describe '#add_situation' do
    it 'stores a situation and returns id' do
      sit = engine.add_situation(content: 'test situation')
      expect(sit[:id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(engine.situations[sit[:id]][:content]).to eq('test situation')
    end
  end

  describe '#generate_view' do
    it 'creates and stores a view for a situation' do
      view = engine.generate_view(
        situation_id:   situation_id,
        perspective_id: ceo_id,
        valence:        0.7,
        concerns:       ['regulatory risk'],
        opportunities:  ['efficiency gains'],
        confidence:     0.85
      )
      expect(engine.situations[situation_id][:views]).to include(view)
    end

    it 'returns error for unknown situation' do
      result = engine.generate_view(situation_id: 'nope', perspective_id: ceo_id)
      expect(result[:error]).to eq(:situation_not_found)
    end

    it 'returns error for unknown perspective' do
      result = engine.generate_view(situation_id: situation_id, perspective_id: 'nope')
      expect(result[:error]).to eq(:perspective_not_found)
    end

    it 'returns error when view limit reached' do
      20.times do |i|
        pid = engine.add_perspective(name: "p#{i}", type: :stakeholder).id
        engine.generate_view(situation_id: situation_id, perspective_id: pid)
      end
      extra_id = engine.add_perspective(name: 'extra', type: :ethical).id
      result = engine.generate_view(situation_id: situation_id, perspective_id: extra_id)
      expect(result[:error]).to eq(:too_many_views)
    end
  end

  describe '#views_for_situation' do
    it 'returns all views for a situation' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -0.3)
      views = engine.views_for_situation(situation_id: situation_id)
      expect(views.size).to eq(2)
    end

    it 'returns empty array for unknown situation' do
      expect(engine.views_for_situation(situation_id: 'nope')).to eq([])
    end
  end

  describe '#perspective_agreement' do
    it 'returns 0.0 when fewer than 2 views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      expect(engine.perspective_agreement(situation_id: situation_id)).to eq(0.0)
    end

    it 'returns high agreement when valences are similar' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: 0.5)
      score = engine.perspective_agreement(situation_id: situation_id)
      expect(score).to be > 0.9
    end

    it 'returns low agreement when valences diverge' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 1.0)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -1.0)
      score = engine.perspective_agreement(situation_id: situation_id)
      expect(score).to be < 0.1
    end
  end

  describe '#blind_spots' do
    it 'returns perspective types not yet applied' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      spots = engine.blind_spots(situation_id: situation_id)
      expect(spots).to include(:ethical, :temporal, :cultural)
      expect(spots).not_to include(:stakeholder)
    end

    it 'returns all types when no views exist' do
      spots = engine.blind_spots(situation_id: situation_id)
      expect(spots).to eq(Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::Constants::PERSPECTIVE_TYPES)
    end
  end

  describe '#coverage_score' do
    it 'returns 0.0 when no perspectives exist' do
      e = described_class.new
      sit = e.add_situation(content: 'x')[:id]
      expect(e.coverage_score(situation_id: sit)).to eq(0.0)
    end

    it 'returns fraction of perspectives covered' do
      # Force all 3 perspectives to exist before generating any views
      ceo_id
      engineer_id
      ethicist_id
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      score = engine.coverage_score(situation_id: situation_id)
      # 1 of 3 perspectives applied
      expect(score).to be_within(0.001).of(1.0 / 3.0)
    end

    it 'returns 1.0 when all perspectives covered' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -0.2)
      engine.generate_view(situation_id: situation_id, perspective_id: ethicist_id, valence: -0.6)
      expect(engine.coverage_score(situation_id: situation_id)).to eq(1.0)
    end
  end

  describe '#dominant_view' do
    it 'returns the view with the highest confidence' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, confidence: 0.5)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, confidence: 0.9)
      dominant = engine.dominant_view(situation_id: situation_id)
      expect(dominant.confidence).to eq(0.9)
    end

    it 'returns nil when no views' do
      expect(engine.dominant_view(situation_id: situation_id)).to be_nil
    end
  end

  describe '#synthesize' do
    it 'returns error when fewer than 2 views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      result = engine.synthesize(situation_id: situation_id)
      expect(result[:error]).to eq(:insufficient_views)
    end

    it 'returns weighted_valence combining all views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id,
                           valence: 1.0, confidence: 1.0)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id,
                           valence: -1.0, confidence: 1.0)
      result = engine.synthesize(situation_id: situation_id)
      expect(result[:weighted_valence]).to be_within(0.001).of(0.0)
    end

    it 'includes unique concerns from all views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id,
                           concerns: ['risk A'], confidence: 0.8)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id,
                           concerns: ['risk B'], confidence: 0.7)
      result = engine.synthesize(situation_id: situation_id)
      expect(result[:concerns]).to include('risk A', 'risk B')
    end

    it 'includes unique opportunities from all views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id,
                           opportunities: ['gain A'], confidence: 0.8)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id,
                           opportunities: ['gain B'], confidence: 0.7)
      result = engine.synthesize(situation_id: situation_id)
      expect(result[:opportunities]).to include('gain A', 'gain B')
    end

    it 'includes view_count, coverage_score, coverage_label, agreement, agreement_label' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, confidence: 0.8)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, confidence: 0.7)
      result = engine.synthesize(situation_id: situation_id)
      expect(result.keys).to include(:view_count, :coverage_score, :coverage_label,
                                     :agreement, :agreement_label)
    end
  end

  describe '#most_divergent_pair' do
    it 'returns nil when fewer than 2 views' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      expect(engine.most_divergent_pair(situation_id: situation_id)).to be_nil
    end

    it 'returns the pair with the largest valence difference' do
      engine.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.9)
      engine.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -0.8)
      engine.generate_view(situation_id: situation_id, perspective_id: ethicist_id, valence: 0.1)
      pair = engine.most_divergent_pair(situation_id: situation_id)
      expect(pair).not_to be_nil
      divergence = (pair[0].valence - pair[1].valence).abs
      expect(divergence).to be_within(0.001).of(1.7)
    end
  end

  describe '#to_h' do
    it 'includes perspective_count and situation_count' do
      ceo_id
      situation_id
      h = engine.to_h
      expect(h[:perspective_count]).to eq(1)
      expect(h[:situation_count]).to eq(1)
    end

    it 'serializes perspectives and situations' do
      ceo_id
      situation_id
      h = engine.to_h
      expect(h[:perspectives].first[:name]).to eq('CEO')
      expect(h[:situations].first[:content]).to eq('Deploy AI hiring tool')
    end
  end
end
