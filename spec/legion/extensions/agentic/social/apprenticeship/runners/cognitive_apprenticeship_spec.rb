# frozen_string_literal: true

require 'legion/extensions/agentic/social/apprenticeship/client'

RSpec.describe Legion::Extensions::Agentic::Social::Apprenticeship::Runners::CognitiveApprenticeship do
  let(:client) { Legion::Extensions::Agentic::Social::Apprenticeship::Client.new }

  let(:valid_params) do
    {
      skill_name:    'ruby',
      domain:        'programming',
      mentor_id:     'mentor-1',
      apprentice_id: 'learner-1'
    }
  end

  def create_one
    client.create_apprenticeship(**valid_params)
  end

  describe '#create_apprenticeship' do
    it 'returns success: true with a valid apprenticeship hash' do
      result = create_one
      expect(result[:success]).to be true
      expect(result[:apprenticeship]).to include(:id, :skill_name, :mastery)
    end

    it 'returns success: false when a param is too short' do
      result = client.create_apprenticeship(skill_name: 'ab', domain: 'dom', mentor_id: 'mtr', apprentice_id: 'app')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:param_too_short)
    end
  end

  describe '#conduct_apprenticeship_session' do
    it 'returns success: true and updated mastery' do
      created = create_one
      id = created[:apprenticeship][:id]
      result = client.conduct_apprenticeship_session(apprenticeship_id: id, method: :modeling, success: true)
      expect(result[:success]).to be true
      expect(result[:apprenticeship][:mastery]).to be > 0.1
    end

    it 'returns success: false for unknown apprenticeship' do
      result = client.conduct_apprenticeship_session(apprenticeship_id: 'nope', method: :modeling, success: true)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns success: false for invalid method' do
      created = create_one
      id = created[:apprenticeship][:id]
      result = client.conduct_apprenticeship_session(apprenticeship_id: id, method: :unknown, success: true)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_method)
    end

    it 'accepts all six valid methods' do
      Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel::METHODS.each do |method|
        c = Legion::Extensions::Agentic::Social::Apprenticeship::Client.new
        created = c.create_apprenticeship(**valid_params)
        id = created[:apprenticeship][:id]
        result = c.conduct_apprenticeship_session(apprenticeship_id: id, method: method, success: true)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#recommend_apprenticeship_method' do
    it 'returns success: true with a valid method' do
      created = create_one
      id = created[:apprenticeship][:id]
      result = client.recommend_apprenticeship_method(apprenticeship_id: id)
      expect(result[:success]).to be true
      expect(Legion::Extensions::Agentic::Social::Apprenticeship::Helpers::ApprenticeshipModel::METHODS).to include(result[:recommended_method])
    end

    it 'returns success: false for unknown apprenticeship' do
      result = client.recommend_apprenticeship_method(apprenticeship_id: 'nope')
      expect(result[:success]).to be false
    end
  end

  describe '#graduated_apprenticeships' do
    it 'returns success: true and an empty list initially' do
      result = client.graduated_apprenticeships
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'includes graduated apprenticeships' do
      created = create_one
      id = created[:apprenticeship][:id]
      30.times { client.conduct_apprenticeship_session(apprenticeship_id: id, method: :exploration, success: true) }
      result = client.graduated_apprenticeships
      expect(result[:count]).to eq(1)
    end
  end

  describe '#active_apprenticeships' do
    it 'returns the newly created apprenticeship' do
      create_one
      result = client.active_apprenticeships
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#mentor_apprenticeships' do
    it 'returns apprenticeships for the mentor' do
      create_one
      result = client.mentor_apprenticeships(mentor_id: 'mentor-1')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#apprentice_apprenticeships' do
    it 'returns apprenticeships for the apprentice' do
      create_one
      result = client.apprentice_apprenticeships(apprentice_id: 'learner-1')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#domain_apprenticeships' do
    it 'returns apprenticeships for the domain' do
      create_one
      result = client.domain_apprenticeships(domain: 'programming')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#update_cognitive_apprenticeship' do
    it 'delegates to conduct_apprenticeship_session' do
      created = create_one
      id = created[:apprenticeship][:id]
      result = client.update_cognitive_apprenticeship(apprenticeship_id: id, method: :coaching, success: true)
      expect(result[:success]).to be true
    end
  end

  describe '#cognitive_apprenticeship_stats' do
    it 'returns success: true with stats' do
      create_one
      result = client.cognitive_apprenticeship_stats
      expect(result[:success]).to be true
      expect(result[:total]).to eq(1)
      expect(result).to include(:active, :graduated, :sessions)
    end
  end
end
