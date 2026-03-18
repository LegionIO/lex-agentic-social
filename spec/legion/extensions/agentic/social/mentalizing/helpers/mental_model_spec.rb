# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mentalizing::Helpers::MentalModel do
  subject(:model) { described_class.new }

  describe '#attribute_belief' do
    it 'stores a belief and returns a BeliefAttribution' do
      belief = model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      expect(belief).to be_a(Legion::Extensions::Agentic::Social::Mentalizing::Helpers::BeliefAttribution)
      expect(belief.agent_id).to eq('alice')
    end

    it 'stores separate beliefs per agent' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      model.attribute_belief(agent_id: 'bob',   subject: 'rain', content: 'no',  confidence: 0.6)
      expect(model.beliefs_for(agent_id: 'alice').size).to eq(1)
      expect(model.beliefs_for(agent_id: 'bob').size).to eq(1)
    end

    it 'caps depth at MAX_RECURSION_DEPTH' do
      belief = model.attribute_belief(agent_id: 'alice', subject: 's', content: 'c', confidence: 0.5, depth: 99)
      expect(belief.depth).to eq(Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::MAX_RECURSION_DEPTH)
    end

    it 'stores about_agent_id when provided' do
      belief = model.attribute_belief(agent_id: 'alice', subject: 'trust', content: 'bob trusts me', confidence: 0.7, about_agent_id: 'bob')
      expect(belief.about_agent_id).to eq('bob')
    end
  end

  describe '#beliefs_for' do
    it 'returns empty array for unknown agent' do
      expect(model.beliefs_for(agent_id: 'nobody')).to eq([])
    end

    it 'returns all beliefs for known agent' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      model.attribute_belief(agent_id: 'alice', subject: 'snow', content: 'no',  confidence: 0.4)
      expect(model.beliefs_for(agent_id: 'alice').size).to eq(2)
    end
  end

  describe '#beliefs_about' do
    it 'returns beliefs where about_agent_id matches' do
      model.attribute_belief(agent_id: 'alice', subject: 'my_trust', content: 'low', confidence: 0.4, about_agent_id: 'me')
      model.attribute_belief(agent_id: 'bob',   subject: 'my_trust', content: 'high', confidence: 0.9, about_agent_id: 'me')
      model.attribute_belief(agent_id: 'carol', subject: 'other',    content: 'n/a',  confidence: 0.5, about_agent_id: 'other')
      result = model.beliefs_about(about_agent_id: 'me')
      expect(result.size).to eq(2)
      expect(result.map(&:agent_id)).to contain_exactly('alice', 'bob')
    end

    it 'returns empty array when no beliefs about agent' do
      expect(model.beliefs_about(about_agent_id: 'nobody')).to eq([])
    end
  end

  describe '#recursive_belief' do
    it 'returns nil when no matching recursive belief exists' do
      result = model.recursive_belief(agent_id: 'alice', about_agent_id: 'bob', subject: 'rain')
      expect(result).to be_nil
    end

    it 'returns the highest-confidence matching belief' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'low',  confidence: 0.4, about_agent_id: 'bob')
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'high', confidence: 0.9, about_agent_id: 'bob')
      result = model.recursive_belief(agent_id: 'alice', about_agent_id: 'bob', subject: 'rain')
      expect(result.content).to eq('high')
    end
  end

  describe '#project_self' do
    it 'creates a depth-1 belief attributed to :self' do
      belief = model.project_self(subject: 'plan', own_belief: 0.8, other_agent_id: 'bob')
      expect(belief.agent_id).to eq(:self)
      expect(belief.depth).to eq(1)
      expect(belief.about_agent_id).to eq('bob')
    end

    it 'discounts confidence by PROJECTION_DISCOUNT' do
      discount = Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::PROJECTION_DISCOUNT
      belief = model.project_self(subject: 'plan', own_belief: 1.0, other_agent_id: 'bob')
      expect(belief.confidence).to be_within(0.001).of(discount)
    end

    it 'clamps discounted confidence to 1.0' do
      belief = model.project_self(subject: 'plan', own_belief: 0.1, other_agent_id: 'bob')
      expect(belief.confidence).to be >= 0.0
      expect(belief.confidence).to be <= 1.0
    end
  end

  describe '#alignment' do
    it 'returns 0.0 when either agent has no beliefs on subject' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      expect(model.alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')).to eq(0.0)
    end

    it 'returns 1.0 when both agents have identical confidence' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.7)
      model.attribute_belief(agent_id: 'bob',   subject: 'rain', content: 'yes', confidence: 0.7)
      expect(model.alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')).to be_within(0.001).of(1.0)
    end

    it 'returns lower score for divergent beliefs' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'high', confidence: 0.9)
      model.attribute_belief(agent_id: 'bob',   subject: 'rain', content: 'low',  confidence: 0.1)
      score = model.alignment(agent_a: 'alice', agent_b: 'bob', subject: 'rain')
      expect(score).to be < 0.5
    end
  end

  describe '#detect_false_belief' do
    it 'returns false_belief: false when belief matches reality' do
      model.attribute_belief(agent_id: 'alice', subject: 'weather', content: 'sunny', confidence: 0.8)
      result = model.detect_false_belief(agent_id: 'alice', subject: 'weather', reality: 'sunny')
      expect(result[:false_belief]).to be false
    end

    it 'returns false_belief: true when belief contradicts reality' do
      model.attribute_belief(agent_id: 'alice', subject: 'weather', content: 'sunny', confidence: 0.8)
      result = model.detect_false_belief(agent_id: 'alice', subject: 'weather', reality: 'raining')
      expect(result[:false_belief]).to be true
      expect(result[:held_belief]).to eq('sunny')
      expect(result[:reality]).to eq('raining')
    end

    it 'returns no_beliefs reason when agent has no beliefs on subject' do
      result = model.detect_false_belief(agent_id: 'nobody', subject: 'weather', reality: 'sunny')
      expect(result[:false_belief]).to be false
      expect(result[:reason]).to eq(:no_beliefs)
    end
  end

  describe '#decay_all' do
    it 'reduces confidence on all beliefs' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      before = model.beliefs_for(agent_id: 'alice').first.confidence
      model.decay_all
      after = model.beliefs_for(agent_id: 'alice').first&.confidence
      expect(after).to be_nil.or be < before
    end

    it 'prunes beliefs at or below BELIEF_FLOOR' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes',
                             confidence: Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::BELIEF_FLOOR)
      model.decay_all
      expect(model.beliefs_for(agent_id: 'alice')).to be_empty
    end
  end

  describe '#remove_agent' do
    it 'removes all beliefs for the agent' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      model.remove_agent(agent_id: 'alice')
      expect(model.beliefs_for(agent_id: 'alice')).to eq([])
    end
  end

  describe '#agent_count and #belief_count' do
    it 'tracks counts correctly' do
      expect(model.agent_count).to eq(0)
      expect(model.belief_count).to eq(0)
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      model.attribute_belief(agent_id: 'bob',   subject: 'snow', content: 'no',  confidence: 0.5)
      expect(model.agent_count).to eq(2)
      expect(model.belief_count).to eq(2)
    end
  end

  describe '#to_h' do
    it 'serializes all beliefs as hashes' do
      model.attribute_belief(agent_id: 'alice', subject: 'rain', content: 'yes', confidence: 0.8)
      h = model.to_h
      expect(h).to have_key('alice')
      expect(h['alice'].first).to include(:agent_id, :subject, :confidence)
    end
  end
end
