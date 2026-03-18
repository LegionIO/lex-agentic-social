# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEvent do
  let(:agent_id)    { 'agent-001' }
  let(:action_type) { :communication }
  let(:context)     { { message: 'hello', intent: 'greet' } }
  let(:valence)     { 0.7 }

  subject(:event) do
    described_class.new(
      agent_id:          agent_id,
      action_type:       action_type,
      context:           context,
      emotional_valence: valence
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns agent_id' do
      expect(event.agent_id).to eq('agent-001')
    end

    it 'normalizes known action_type' do
      expect(event.action_type).to eq(:communication)
    end

    it 'normalizes unknown action_type to :unknown' do
      e = described_class.new(agent_id: 'x', action_type: :nonexistent)
      expect(e.action_type).to eq(:unknown)
    end

    it 'assigns string action_type by converting to symbol' do
      e = described_class.new(agent_id: 'x', action_type: 'decision')
      expect(e.action_type).to eq(:decision)
    end

    it 'assigns context hash' do
      expect(event.context).to eq(context)
    end

    it 'treats non-hash context as empty hash' do
      e = described_class.new(agent_id: 'x', action_type: :movement, context: 'not a hash')
      expect(e.context).to eq({})
    end

    it 'clamps emotional_valence to [-1, 1]' do
      e = described_class.new(agent_id: 'x', action_type: :movement, emotional_valence: 1.5)
      expect(e.emotional_valence).to eq(1.0)
    end

    it 'clamps negative emotional_valence' do
      e = described_class.new(agent_id: 'x', action_type: :movement, emotional_valence: -2.0)
      expect(e.emotional_valence).to eq(-1.0)
    end

    it 'assigns observed_at as a Time' do
      expect(event.observed_at).to be_a(Time)
    end

    it 'defaults context to empty hash' do
      e = described_class.new(agent_id: 'x', action_type: :unknown)
      expect(e.context).to eq({})
    end

    it 'defaults emotional_valence to 0.0' do
      e = described_class.new(agent_id: 'x', action_type: :unknown)
      expect(e.emotional_valence).to eq(0.0)
    end
  end

  describe '#to_h' do
    subject(:hash) { event.to_h }

    it 'includes id' do
      expect(hash[:id]).to eq(event.id)
    end

    it 'includes agent_id' do
      expect(hash[:agent_id]).to eq('agent-001')
    end

    it 'includes action_type' do
      expect(hash[:action_type]).to eq(:communication)
    end

    it 'includes context' do
      expect(hash[:context]).to eq(context)
    end

    it 'includes emotional_valence' do
      expect(hash[:emotional_valence]).to eq(0.7)
    end

    it 'includes observed_at' do
      expect(hash[:observed_at]).to be_a(Time)
    end
  end
end
