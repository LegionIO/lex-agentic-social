# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mentalizing::Helpers::BeliefAttribution do
  subject(:belief) do
    described_class.new(
      agent_id:   'alice',
      subject:    'weather',
      content:    'it will rain',
      confidence: 0.7,
      depth:      1
    )
  end

  describe '#initialize' do
    it 'assigns fields correctly' do
      expect(belief.agent_id).to eq('alice')
      expect(belief.subject).to eq('weather')
      expect(belief.content).to eq('it will rain')
      expect(belief.depth).to eq(1)
      expect(belief.about_agent_id).to be_nil
    end

    it 'clamps confidence to 0.0..1.0' do
      over  = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 1.5)
      under = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: -0.5)
      expect(over.confidence).to eq(1.0)
      expect(under.confidence).to eq(0.0)
    end

    it 'assigns a uuid id' do
      expect(belief.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'records created_at' do
      expect(belief.created_at).to be_a(Time)
    end
  end

  describe '#decay' do
    it 'reduces confidence by BELIEF_DECAY' do
      before = belief.confidence
      belief.decay
      expect(belief.confidence).to be_within(0.001).of(before - Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::BELIEF_DECAY)
    end

    it 'does not drop below BELIEF_FLOOR' do
      20.times { belief.decay }
      expect(belief.confidence).to be >= Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::BELIEF_FLOOR
    end
  end

  describe '#reinforce' do
    it 'increases confidence by CONFIDENCE_ALPHA by default' do
      belief_low = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.3)
      before = belief_low.confidence
      belief_low.reinforce
      expect(belief_low.confidence).to be_within(0.001).of(before + Legion::Extensions::Agentic::Social::Mentalizing::Helpers::Constants::CONFIDENCE_ALPHA)
    end

    it 'does not exceed 1.0' do
      high = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.95)
      high.reinforce(amount: 0.5)
      expect(high.confidence).to eq(1.0)
    end

    it 'accepts custom amount' do
      low = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.2)
      low.reinforce(amount: 0.3)
      expect(low.confidence).to be_within(0.001).of(0.5)
    end
  end

  describe '#label' do
    it 'returns :certain for high confidence' do
      high = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.9)
      expect(high.label).to eq(:certain)
    end

    it 'returns :confident for 0.6..0.8 range' do
      mid = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.7)
      expect(mid.label).to eq(:confident)
    end

    it 'returns :uncertain for 0.4..0.6 range' do
      unc = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.5)
      expect(unc.label).to eq(:uncertain)
    end

    it 'returns :speculative for 0.2..0.4 range' do
      spec_b = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.3)
      expect(spec_b.label).to eq(:speculative)
    end

    it 'returns :unknown for very low confidence' do
      low = described_class.new(agent_id: 'a', subject: 's', content: 'c', confidence: 0.1)
      expect(low.label).to eq(:unknown)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = belief.to_h
      expect(h).to include(:id, :agent_id, :subject, :content, :confidence, :depth, :about_agent_id, :label, :created_at)
      expect(h[:agent_id]).to eq('alice')
      expect(h[:depth]).to eq(1)
    end
  end
end
