# frozen_string_literal: true

require 'legion/extensions/agentic/social/perspective_shifting/client'

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Runners::PerspectiveShifting do
  let(:client) { Legion::Extensions::Agentic::Social::PerspectiveShifting::Client.new }

  let(:ceo_id) do
    client.add_perspective(name: 'CEO', type: :stakeholder, priorities: %i[growth])[:perspective][:id]
  end

  let(:engineer_id) do
    client.add_perspective(name: 'Engineer', type: :pragmatic, priorities: %i[stability])[:perspective][:id]
  end

  let(:ethicist_id) do
    client.add_perspective(name: 'Ethicist', type: :ethical, empathy: 0.9)[:perspective][:id]
  end

  let(:situation_id) do
    client.add_situation(content: 'Deploy AI hiring tool')[:situation_id]
  end

  # --- Perspective management ---

  describe '#add_perspective' do
    it 'returns success: true with perspective hash' do
      result = client.add_perspective(name: 'Manager', type: :stakeholder)
      expect(result[:success]).to be true
      expect(result[:perspective][:name]).to eq('Manager')
    end

    it 'returns success: false for invalid type' do
      result = client.add_perspective(name: 'x', type: :unknown)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_type)
    end

    it 'stores empathy_level on the perspective' do
      result = client.add_perspective(name: 'Doctor', type: :emotional, empathy: 0.9)
      expect(result[:perspective][:empathy_level]).to be_within(0.001).of(0.9)
    end

    it 'stores bias_toward when provided' do
      result = client.add_perspective(name: 'Lawyer', type: :ethical, bias: :caution)
      expect(result[:perspective][:bias_toward]).to eq(:caution)
    end

    it 'stores expertise_domains' do
      result = client.add_perspective(name: 'Scientist', type: :pragmatic,
                                      expertise_domains: %w[biology data])
      expect(result[:perspective][:expertise_domains]).to eq(%w[biology data])
    end
  end

  describe '#list_perspectives' do
    it 'returns success: true with empty list initially' do
      result = client.list_perspectives
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'returns all added perspectives' do
      ceo_id
      engineer_id
      result = client.list_perspectives
      expect(result[:count]).to eq(2)
    end
  end

  describe '#get_perspective' do
    it 'returns found: true for known perspective' do
      id = ceo_id
      result = client.get_perspective(perspective_id: id)
      expect(result[:found]).to be true
      expect(result[:perspective][:name]).to eq('CEO')
    end

    it 'returns found: false for unknown perspective' do
      result = client.get_perspective(perspective_id: 'nope')
      expect(result[:found]).to be false
    end
  end

  # --- Situation management ---

  describe '#add_situation' do
    it 'returns success: true with situation_id' do
      result = client.add_situation(content: 'new deployment')
      expect(result[:success]).to be true
      expect(result[:situation_id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#list_situations' do
    it 'returns all added situations' do
      situation_id
      result = client.list_situations
      expect(result[:count]).to eq(1)
      expect(result[:situations].first[:content]).to eq('Deploy AI hiring tool')
    end
  end

  # --- View generation ---

  describe '#generate_view' do
    it 'returns success: true with view hash' do
      result = client.generate_view(
        situation_id:   situation_id,
        perspective_id: ceo_id,
        valence:        0.7,
        concerns:       ['cost'],
        opportunities:  ['efficiency'],
        confidence:     0.85
      )
      expect(result[:success]).to be true
      expect(result[:view][:valence]).to be_within(0.001).of(0.7)
    end

    it 'returns error for unknown situation' do
      result = client.generate_view(situation_id: 'nope', perspective_id: ceo_id)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:situation_not_found)
    end

    it 'returns error for unknown perspective' do
      result = client.generate_view(situation_id: situation_id, perspective_id: 'nope')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:perspective_not_found)
    end
  end

  describe '#views_for_situation' do
    it 'returns empty list when no views exist' do
      result = client.views_for_situation(situation_id: situation_id)
      expect(result[:count]).to eq(0)
    end

    it 'returns all views after generating them' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -0.3)
      result = client.views_for_situation(situation_id: situation_id)
      expect(result[:count]).to eq(2)
    end
  end

  # --- Analysis ---

  describe '#perspective_agreement' do
    it 'returns 0.0 with fewer than 2 views' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      result = client.perspective_agreement(situation_id: situation_id)
      expect(result[:agreement]).to eq(0.0)
    end

    it 'returns label alongside score' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5, confidence: 0.8)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: 0.5, confidence: 0.7)
      result = client.perspective_agreement(situation_id: situation_id)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns low agreement when views conflict' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 1.0, confidence: 0.8)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -1.0, confidence: 0.7)
      result = client.perspective_agreement(situation_id: situation_id)
      expect(result[:agreement]).to be < 0.1
      expect(result[:label]).to eq(:conflict)
    end
  end

  describe '#blind_spots' do
    it 'returns all perspective types as blind spots when no views' do
      result = client.blind_spots(situation_id: situation_id)
      expect(result[:blind_spots]).to eq(Legion::Extensions::Agentic::Social::PerspectiveShifting::Helpers::Constants::PERSPECTIVE_TYPES)
    end

    it 'excludes covered perspective types' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      result = client.blind_spots(situation_id: situation_id)
      expect(result[:blind_spots]).not_to include(:stakeholder)
      expect(result[:blind_spots]).to include(:ethical)
    end
  end

  describe '#coverage_score' do
    it 'returns 0.0 when no views' do
      result = client.coverage_score(situation_id: situation_id)
      expect(result[:coverage]).to eq(0.0)
    end

    it 'returns label alongside score' do
      ceo_id
      result = client.coverage_score(situation_id: situation_id)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'increases as more perspectives are applied' do
      ceo_id
      before = client.coverage_score(situation_id: situation_id)[:coverage]
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id)
      after = client.coverage_score(situation_id: situation_id)[:coverage]
      expect(after).to be > before
    end
  end

  describe '#dominant_view' do
    it 'returns found: false when no views' do
      result = client.dominant_view(situation_id: situation_id)
      expect(result[:found]).to be false
    end

    it 'returns the highest confidence view' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, confidence: 0.4)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id, confidence: 0.9)
      result = client.dominant_view(situation_id: situation_id)
      expect(result[:found]).to be true
      expect(result[:view][:confidence]).to be_within(0.001).of(0.9)
    end
  end

  describe '#synthesize' do
    it 'returns error when fewer than 2 views' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      result = client.synthesize(situation_id: situation_id)
      expect(result[:success]).to be false
    end

    it 'returns success: true with weighted_valence' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id,
                           valence: 0.8, confidence: 1.0)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id,
                           valence: -0.2, confidence: 1.0)
      result = client.synthesize(situation_id: situation_id)
      expect(result[:success]).to be true
      expect(result[:weighted_valence]).to be_within(0.001).of(0.3)
    end

    it 'merges concerns and opportunities across all views' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id,
                           concerns: ['budget'], opportunities: ['scale'], confidence: 0.8)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id,
                           concerns: ['tech debt'], opportunities: ['automation'], confidence: 0.7)
      result = client.synthesize(situation_id: situation_id)
      expect(result[:concerns]).to include('budget', 'tech debt')
      expect(result[:opportunities]).to include('scale', 'automation')
    end
  end

  describe '#most_divergent_pair' do
    it 'returns found: false with fewer than 2 views' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.5)
      result = client.most_divergent_pair(situation_id: situation_id)
      expect(result[:found]).to be false
    end

    it 'returns found: true with divergence value' do
      client.generate_view(situation_id: situation_id, perspective_id: ceo_id, valence: 0.9)
      client.generate_view(situation_id: situation_id, perspective_id: engineer_id, valence: -0.8)
      result = client.most_divergent_pair(situation_id: situation_id)
      expect(result[:found]).to be true
      expect(result[:divergence]).to be_within(0.001).of(1.7)
      expect(result[:views].size).to eq(2)
    end
  end

  describe '#engine_status' do
    it 'returns success: true with perspective and situation counts' do
      ceo_id
      situation_id
      result = client.engine_status
      expect(result[:success]).to be true
      expect(result[:perspective_count]).to eq(1)
      expect(result[:situation_count]).to eq(1)
    end
  end
end
