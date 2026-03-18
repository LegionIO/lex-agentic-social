# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel do
  subject(:model) { described_class }

  describe 'constants' do
    it 'defines METHODS with six items' do
      expect(model::METHODS.size).to eq(6)
      expect(model::METHODS).to include(:modeling, :coaching, :scaffolding, :articulation, :reflection, :exploration)
    end

    it 'defines MASTERY_THRESHOLD as 0.85' do
      expect(model::MASTERY_THRESHOLD).to eq(0.85)
    end

    it 'defines LEARNING_GAIN as 0.08' do
      expect(model::LEARNING_GAIN).to eq(0.08)
    end

    it 'defines EXPLORATION_MULTIPLIER as 2.0' do
      expect(model::EXPLORATION_MULTIPLIER).to eq(2.0)
    end

    it 'defines COACHING_MULTIPLIER as 1.5' do
      expect(model::COACHING_MULTIPLIER).to eq(1.5)
    end

    it 'defines DECAY_RATE as 0.01' do
      expect(model::DECAY_RATE).to eq(0.01)
    end
  end

  describe '.phase_for' do
    it 'returns :modeling for mastery 0.0..0.19' do
      expect(model.phase_for(0.0)).to eq(:modeling)
      expect(model.phase_for(0.1)).to eq(:modeling)
    end

    it 'returns :coaching for mastery 0.2..0.39' do
      expect(model.phase_for(0.2)).to eq(:coaching)
      expect(model.phase_for(0.3)).to eq(:coaching)
    end

    it 'returns :scaffolding for mastery 0.4..0.59' do
      expect(model.phase_for(0.4)).to eq(:scaffolding)
    end

    it 'returns :articulation for mastery 0.6..0.74' do
      expect(model.phase_for(0.6)).to eq(:articulation)
    end

    it 'returns :reflection for mastery 0.75..0.84' do
      expect(model.phase_for(0.75)).to eq(:reflection)
    end

    it 'returns :exploration for mastery >= 0.85' do
      expect(model.phase_for(0.85)).to eq(:exploration)
      expect(model.phase_for(1.0)).to eq(:exploration)
    end
  end

  describe '.mastery_label_for' do
    it 'returns :novice for mastery < 0.2' do
      expect(model.mastery_label_for(0.1)).to eq(:novice)
    end

    it 'returns :apprentice for mastery 0.2..0.39' do
      expect(model.mastery_label_for(0.3)).to eq(:apprentice)
    end

    it 'returns :intermediate for mastery 0.4..0.59' do
      expect(model.mastery_label_for(0.5)).to eq(:intermediate)
    end

    it 'returns :proficient for mastery 0.6..0.79' do
      expect(model.mastery_label_for(0.7)).to eq(:proficient)
    end

    it 'returns :expert for mastery >= 0.8' do
      expect(model.mastery_label_for(0.9)).to eq(:expert)
    end
  end

  describe '.clamp_mastery' do
    it 'floors at MASTERY_FLOOR' do
      expect(model.clamp_mastery(-0.5)).to eq(0.0)
    end

    it 'caps at MASTERY_CEILING' do
      expect(model.clamp_mastery(1.5)).to eq(1.0)
    end

    it 'passes through valid values' do
      expect(model.clamp_mastery(0.5)).to eq(0.5)
    end
  end

  describe '.new_apprenticeship' do
    let(:entry) do
      model.new_apprenticeship(
        skill_name:    'ruby',
        domain:        'programming',
        mentor_id:     'mentor-1',
        apprentice_id: 'apprentice-1'
      )
    end

    it 'sets default mastery' do
      expect(entry[:mastery]).to eq(model::DEFAULT_MASTERY)
    end

    it 'sets current_phase from mastery' do
      expect(entry[:current_phase]).to eq(model.phase_for(model::DEFAULT_MASTERY))
    end

    it 'generates a uuid id' do
      expect(entry[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets session_count to 0' do
      expect(entry[:session_count]).to eq(0)
    end
  end
end
