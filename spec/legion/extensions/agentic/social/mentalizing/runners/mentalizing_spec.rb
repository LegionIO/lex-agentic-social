# frozen_string_literal: true

require 'legion/extensions/agentic/social/mentalizing/client'

RSpec.describe Legion::Extensions::Agentic::Social::Mentalizing::Runners::Mentalizing do
  let(:client) { Legion::Extensions::Agentic::Social::Mentalizing::Client.new }

  describe '#attribute_belief' do
    it 'returns attributed: true with belief hash' do
      result = client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      expect(result[:attributed]).to be true
      expect(result[:belief]).to include(:id, :agent_id, :subject, :content, :confidence, :depth)
    end

    it 'defaults confidence to DEFAULT_CONFIDENCE when not provided' do
      result = client.attribute_belief(agent_id: 'alice', subject: 'snow', content: 'maybe')
      expect(result[:belief][:confidence]).to eq(Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::DEFAULT_CONFIDENCE)
    end

    it 'caps depth at MAX_RECURSION_DEPTH' do
      result = client.attribute_belief(agent_id: 'alice', subject: 's', content: 'c', depth: 100)
      expect(result[:belief][:depth]).to eq(Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::MAX_RECURSION_DEPTH)
    end

    it 'accepts depth 0 (first-order)' do
      result = client.attribute_belief(agent_id: 'alice', subject: 'trust', content: 'high', confidence: 0.9, depth: 0)
      expect(result[:belief][:depth]).to eq(0)
    end

    it 'stores about_agent_id for second-order beliefs' do
      result = client.attribute_belief(agent_id: 'alice', subject: 'plan', content: 'I will act', confidence: 0.7,
                                       depth: 1, about_agent_id: 'bob')
      expect(result[:belief][:about_agent_id]).to eq('bob')
    end
  end

  describe '#project_belief' do
    it 'returns projected: true with discounted confidence' do
      result = client.project_belief(subject: 'plan', own_belief: 0.8, other_agent_id: 'bob')
      expect(result[:projected]).to be true
      discount = Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::PROJECTION_DISCOUNT
      expect(result[:belief][:confidence]).to be_within(0.001).of(0.8 * discount)
    end

    it 'creates depth-1 belief about the other agent' do
      result = client.project_belief(subject: 'plan', own_belief: 1.0, other_agent_id: 'carol')
      expect(result[:belief][:depth]).to eq(1)
      expect(result[:belief][:about_agent_id]).to eq('carol')
    end
  end

  describe '#check_alignment' do
    it 'returns alignment score of 0.0 when no shared beliefs' do
      result = client.check_alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')
      expect(result[:alignment]).to eq(0.0)
    end

    it 'returns alignment near 1.0 for identical confidences' do
      client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.7)
      client.attribute_belief(agent_id: 'bob',   subject: 'rain', content: 'yes', confidence: 0.7)
      result = client.check_alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')
      expect(result[:alignment]).to be_within(0.001).of(1.0)
    end

    it 'returns subject in result' do
      result = client.check_alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')
      expect(result[:subject]).to eq('rain')
    end
  end

  describe '#detect_false_belief' do
    it 'detects false belief when agent belief contradicts reality' do
      client.attribute_belief(agent_id: 'alice', subject: 'weather', content: 'sunny', confidence: 0.9)
      result = client.detect_false_belief(agent_id: 'alice', subject: 'weather', reality: 'raining')
      expect(result[:false_belief]).to be true
      expect(result[:held_belief]).to eq('sunny')
    end

    it 'returns false_belief: false when belief matches reality' do
      client.attribute_belief(agent_id: 'alice', subject: 'weather', content: 'sunny', confidence: 0.9)
      result = client.detect_false_belief(agent_id: 'alice', subject: 'weather', reality: 'sunny')
      expect(result[:false_belief]).to be false
    end

    it 'returns no_beliefs reason when agent unknown' do
      result = client.detect_false_belief(agent_id: 'nobody', subject: 'weather', reality: 'sunny')
      expect(result[:reason]).to eq(:no_beliefs)
    end
  end

  describe '#beliefs_for_agent' do
    it 'returns empty beliefs for unknown agent' do
      result = client.beliefs_for_agent(agent_id: 'nobody')
      expect(result[:beliefs]).to eq([])
      expect(result[:count]).to eq(0)
    end

    it 'returns beliefs for known agent' do
      client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      result = client.beliefs_for_agent(agent_id: 'alice')
      expect(result[:count]).to eq(1)
      expect(result[:beliefs].first[:agent_id]).to eq('alice')
    end
  end

  describe '#beliefs_about_agent' do
    it 'returns beliefs where about_agent_id matches' do
      client.attribute_belief(agent_id: 'alice', subject: 'my_reliability', content: 'high', confidence: 0.8, about_agent_id: 'me')
      client.attribute_belief(agent_id: 'bob',   subject: 'my_reliability', content: 'low',  confidence: 0.3, about_agent_id: 'me')
      result = client.beliefs_about_agent(about_agent_id: 'me')
      expect(result[:count]).to eq(2)
    end

    it 'returns empty when no beliefs about agent' do
      result = client.beliefs_about_agent(about_agent_id: 'nobody')
      expect(result[:count]).to eq(0)
    end
  end

  describe '#recursive_belief_lookup' do
    it 'returns found: false when no match' do
      result = client.recursive_belief_lookup(agent_id: 'alice', about_agent_id: 'bob', subject: 'rain')
      expect(result[:found]).to be false
    end

    it 'returns found: true with belief when match exists' do
      client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'bob thinks rain', confidence: 0.75, about_agent_id: 'bob')
      result = client.recursive_belief_lookup(agent_id: 'alice', about_agent_id: 'bob', subject: 'rain')
      expect(result[:found]).to be true
      expect(result[:belief][:content]).to eq('bob thinks rain')
    end
  end

  describe '#update_mentalizing' do
    it 'returns decayed: true' do
      result = client.update_mentalizing
      expect(result[:decayed]).to be true
    end

    it 'returns agent and belief counts' do
      client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      result = client.update_mentalizing
      expect(result).to have_key(:agents)
      expect(result).to have_key(:beliefs)
    end
  end

  describe '#mentalizing_stats' do
    it 'returns agents and beliefs counts' do
      result = client.mentalizing_stats
      expect(result).to include(:agents, :beliefs)
    end

    it 'reflects current state' do
      client.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      client.attribute_belief(agent_id: 'bob',   subject: 'snow', content: 'no',  confidence: 0.5)
      result = client.mentalizing_stats
      expect(result[:agents]).to eq(2)
      expect(result[:beliefs]).to eq(2)
    end
  end
end
