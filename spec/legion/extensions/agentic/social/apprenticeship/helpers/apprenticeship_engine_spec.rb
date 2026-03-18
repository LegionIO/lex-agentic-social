# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipEngine do
  let(:engine) { described_class.new }

  let(:params) do
    {
      skill_name:    'terraform',
      domain:        'infrastructure',
      mentor_id:     'mentor-1',
      apprentice_id: 'learner-1'
    }
  end

  def create_one
    engine.create_apprenticeship(**params)
  end

  describe '#create_apprenticeship' do
    it 'returns a new Apprenticeship' do
      appr = create_one
      expect(appr).to be_a(Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::Apprenticeship)
    end

    it 'stores the apprenticeship' do
      appr = create_one
      expect(engine.get(appr.id)).to eq(appr)
    end

    it 'increments count' do
      expect { create_one }.to change(engine, :count).by(1)
    end

    it 'returns nil at capacity' do
      stub_const('Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel::MAX_APPRENTICESHIPS', 1)
      create_one
      expect(engine.create_apprenticeship(**params)).to be_nil
    end
  end

  describe '#conduct_session' do
    it 'returns the apprenticeship after learning' do
      appr = create_one
      result = engine.conduct_session(apprenticeship_id: appr.id, method: :modeling, success: true)
      expect(result).to eq(appr)
    end

    it 'returns nil for unknown id' do
      expect(engine.conduct_session(apprenticeship_id: 'nope', method: :modeling, success: true)).to be_nil
    end

    it 'records the session' do
      appr = create_one
      engine.conduct_session(apprenticeship_id: appr.id, method: :coaching, success: true)
      expect(engine.sessions.size).to eq(1)
    end
  end

  describe '#recommend_method' do
    it 'returns the recommended method' do
      appr = create_one
      method = engine.recommend_method(apprenticeship_id: appr.id)
      expect(Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel::METHODS).to include(method)
    end

    it 'returns nil for unknown id' do
      expect(engine.recommend_method(apprenticeship_id: 'nope')).to be_nil
    end
  end

  describe '#graduated_apprenticeships' do
    it 'returns apprenticeships that have graduated' do
      appr = create_one
      30.times { engine.conduct_session(apprenticeship_id: appr.id, method: :exploration, success: true) }
      expect(engine.graduated_apprenticeships).to include(appr)
    end

    it 'excludes non-graduated apprenticeships' do
      create_one
      expect(engine.graduated_apprenticeships).to be_empty
    end
  end

  describe '#active_apprenticeships' do
    it 'returns non-graduated apprenticeships' do
      create_one
      expect(engine.active_apprenticeships.size).to eq(1)
    end

    it 'excludes graduated apprenticeships' do
      appr = create_one
      30.times { engine.conduct_session(apprenticeship_id: appr.id, method: :exploration, success: true) }
      expect(engine.active_apprenticeships).to be_empty
    end
  end

  describe '#by_mentor' do
    it 'returns apprenticeships for the given mentor' do
      create_one
      result = engine.by_mentor(mentor_id: 'mentor-1')
      expect(result.size).to eq(1)
    end

    it 'returns empty for unknown mentor' do
      create_one
      expect(engine.by_mentor(mentor_id: 'nobody')).to be_empty
    end
  end

  describe '#by_apprentice' do
    it 'returns apprenticeships for the given apprentice' do
      create_one
      result = engine.by_apprentice(apprentice_id: 'learner-1')
      expect(result.size).to eq(1)
    end
  end

  describe '#by_domain' do
    it 'returns apprenticeships in the given domain' do
      create_one
      result = engine.by_domain(domain: 'infrastructure')
      expect(result.size).to eq(1)
    end

    it 'returns empty for unknown domain' do
      create_one
      expect(engine.by_domain(domain: 'unknown')).to be_empty
    end
  end

  describe '#decay_all' do
    it 'applies decay to all apprenticeships and returns count' do
      create_one
      expect(engine.decay_all).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns a summary hash' do
      create_one
      h = engine.to_h
      expect(h).to include(:total, :active, :graduated, :sessions)
      expect(h[:total]).to eq(1)
    end
  end
end
