# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Runners::Observe do
  let(:engine) { Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEngine.new }

  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#observe_action' do
    it 'returns success: true' do
      result = host.observe_action(agent_id: 'agent-1', action_type: :communication, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns the observed event hash' do
      result = host.observe_action(agent_id: 'agent-1', action_type: :decision, engine: engine)
      expect(result[:event]).to be_a(Hash)
      expect(result[:event][:action_type]).to eq(:decision)
    end

    it 'returns a resonance_tier symbol' do
      result = host.observe_action(agent_id: 'agent-1', action_type: :communication, engine: engine)
      expect(result[:resonance_tier]).to be_a(Symbol)
    end

    it 'accepts unknown action_type gracefully' do
      result = host.observe_action(agent_id: 'agent-1', action_type: :something_weird, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:event][:action_type]).to eq(:unknown)
    end

    it 'passes emotional_valence to the event' do
      result = host.observe_action(
        agent_id: 'agent-1', action_type: :emotional_expression,
        emotional_valence: 0.8, engine: engine
      )
      expect(result[:event][:emotional_valence]).to eq(0.8)
    end

    it 'passes context to the event' do
      ctx = { detail: 'test' }
      result = host.observe_action(
        agent_id: 'agent-1', action_type: :communication,
        context: ctx, engine: engine
      )
      expect(result[:event][:context]).to eq(ctx)
    end
  end

  describe '#list_events' do
    before do
      host.observe_action(agent_id: 'agent-1', action_type: :communication, engine: engine)
      host.observe_action(agent_id: 'agent-2', action_type: :decision, engine: engine)
    end

    it 'returns all events when no agent_id given' do
      result = host.list_events(engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:count]).to eq(2)
    end

    it 'filters by agent_id' do
      result = host.list_events(agent_id: 'agent-1', engine: engine)
      expect(result[:count]).to eq(1)
      expect(result[:events].first[:agent_id]).to eq('agent-1')
    end

    it 'returns empty list for unknown agent' do
      result = host.list_events(agent_id: 'nobody', engine: engine)
      expect(result[:count]).to eq(0)
      expect(result[:events]).to be_empty
    end
  end
end
