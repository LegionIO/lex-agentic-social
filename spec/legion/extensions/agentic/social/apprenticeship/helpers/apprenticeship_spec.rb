# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::Apprenticeship do
  let(:appr) do
    described_class.new(
      skill_name:    'ruby',
      domain:        'programming',
      mentor_id:     'mentor-1',
      apprentice_id: 'apprentice-1'
    )
  end

  describe '#initialize' do
    it 'sets skill_name' do
      expect(appr.skill_name).to eq('ruby')
    end

    it 'sets domain' do
      expect(appr.domain).to eq('programming')
    end

    it 'starts at DEFAULT_MASTERY' do
      expect(appr.mastery).to eq(Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel::DEFAULT_MASTERY)
    end

    it 'starts with zero sessions' do
      expect(appr.session_count).to eq(0)
    end

    it 'generates a uuid' do
      expect(appr.id).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#current_phase' do
    it 'returns :modeling at default mastery' do
      expect(appr.current_phase).to eq(:modeling)
    end
  end

  describe '#mastery_label' do
    it 'returns :novice at default mastery' do
      expect(appr.mastery_label).to eq(:novice)
    end
  end

  describe '#graduated?' do
    it 'returns false below threshold' do
      expect(appr.graduated?).to be false
    end

    it 'returns true at threshold' do
      30.times { appr.learn!(method: :exploration, success: true) }
      expect(appr.graduated?).to be true
    end
  end

  describe '#recommended_method' do
    it 'returns :modeling at default mastery' do
      expect(appr.recommended_method).to eq(:modeling)
    end
  end

  describe '#learn!' do
    it 'increases mastery on success' do
      before = appr.mastery
      appr.learn!(method: :modeling, success: true)
      expect(appr.mastery).to be > before
    end

    it 'does not increase mastery on failure' do
      before = appr.mastery
      appr.learn!(method: :modeling, success: false)
      expect(appr.mastery).to eq(before)
    end

    it 'applies exploration multiplier' do
      a1 = described_class.new(skill_name: 'skill', domain: 'dom', mentor_id: 'mtr', apprentice_id: 'app')
      a2 = described_class.new(skill_name: 'skill', domain: 'dom', mentor_id: 'mtr', apprentice_id: 'app')
      a1.learn!(method: :modeling, success: true)
      a2.learn!(method: :exploration, success: true)
      expect(a2.mastery).to be > a1.mastery
    end

    it 'applies coaching multiplier' do
      a1 = described_class.new(skill_name: 'skill', domain: 'dom', mentor_id: 'mtr', apprentice_id: 'app')
      a2 = described_class.new(skill_name: 'skill', domain: 'dom', mentor_id: 'mtr', apprentice_id: 'app')
      a1.learn!(method: :modeling, success: true)
      a2.learn!(method: :coaching, success: true)
      expect(a2.mastery).to be > a1.mastery
    end

    it 'increments session_count' do
      appr.learn!(method: :scaffolding, success: true)
      expect(appr.session_count).to eq(1)
    end

    it 'clamps mastery at ceiling' do
      100.times { appr.learn!(method: :exploration, success: true) }
      expect(appr.mastery).to be <= 1.0
    end

    it 'updates last_session_at' do
      appr.learn!(method: :reflection, success: true)
      expect(appr.last_session_at).not_to be_nil
    end
  end

  describe '#decay!' do
    it 'reduces mastery' do
      appr.learn!(method: :exploration, success: true)
      before = appr.mastery
      appr.decay!
      expect(appr.mastery).to be < before
    end

    it 'clamps at floor' do
      100.times { appr.decay! }
      expect(appr.mastery).to be >= 0.0
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = appr.to_h
      expect(h).to include(:id, :skill_name, :domain, :mentor_id, :apprentice_id,
                           :mastery, :current_phase, :mastery_label, :graduated,
                           :session_count, :created_at, :last_session_at)
    end

    it 'reflects graduated status' do
      30.times { appr.learn!(method: :exploration, success: true) }
      expect(appr.to_h[:graduated]).to be true
    end
  end
end
