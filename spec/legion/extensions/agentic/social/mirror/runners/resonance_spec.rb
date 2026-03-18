# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Runners::Resonance do
  let(:engine) { Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEngine.new }

  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#empathic_resonance' do
    it 'returns success: true' do
      result = host.empathic_resonance(agent_id: 'agent-1', engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns resonance value in [0, 1]' do
      result = host.empathic_resonance(agent_id: 'agent-1', engine: engine)
      expect(result[:resonance]).to be_between(0.0, 1.0)
    end

    it 'returns resonance_label and empathy_label symbols' do
      result = host.empathic_resonance(agent_id: 'agent-1', engine: engine)
      expect(result[:resonance_label]).to be_a(Symbol)
      expect(result[:empathy_label]).to be_a(Symbol)
    end

    it 'returns accuracy as nil for new agent with no simulations' do
      result = host.empathic_resonance(agent_id: 'brand-new', engine: engine)
      expect(result[:accuracy]).to be_nil
    end

    it 'returns event_count and simulation_count' do
      event = engine.observe(agent_id: 'agent-1', action_type: :communication)
      engine.simulate(event)
      result = host.empathic_resonance(agent_id: 'agent-1', engine: engine)
      expect(result[:event_count]).to eq(1)
      expect(result[:simulation_count]).to eq(1)
    end

    it 'returns :moderate label for DEFAULT_RESONANCE' do
      result = host.empathic_resonance(agent_id: 'new-agent', engine: engine)
      expect(result[:resonance_label]).to eq(:moderate)
    end
  end

  describe '#decay_resonances' do
    context 'with agent_id specified' do
      before { engine.boost_resonance('agent-1') }

      it 'returns success: true' do
        result = host.decay_resonances(agent_id: 'agent-1', engine: engine)
        expect(result[:success]).to be(true)
      end

      it 'returns resonance_after' do
        before = engine.empathic_resonance('agent-1')
        result = host.decay_resonances(agent_id: 'agent-1', engine: engine)
        expect(result[:resonance_after]).to be < before
      end

      it 'returns agent_id in response' do
        result = host.decay_resonances(agent_id: 'agent-1', engine: engine)
        expect(result[:agent_id]).to eq('agent-1')
      end
    end

    context 'without agent_id (global decay)' do
      before do
        engine.boost_resonance('agent-a')
        engine.boost_resonance('agent-b')
      end

      it 'returns success: true' do
        result = host.decay_resonances(engine: engine)
        expect(result[:success]).to be(true)
      end

      it 'returns agents_decayed count' do
        result = host.decay_resonances(engine: engine)
        expect(result[:agents_decayed]).to eq(2)
      end

      it 'returns resonances hash' do
        result = host.decay_resonances(engine: engine)
        expect(result[:resonances]).to be_a(Hash)
        expect(result[:resonances].keys).to include('agent-a', 'agent-b')
      end
    end
  end

  describe '#resonance_summary' do
    before do
      engine.boost_resonance('agent-x')
      engine.boost_resonance('agent-y')
    end

    it 'returns success: true' do
      result = host.resonance_summary(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'lists all known agents' do
      result = host.resonance_summary(engine: engine)
      expect(result[:total]).to eq(2)
    end

    it 'includes empathy_label for each agent' do
      result = host.resonance_summary(engine: engine)
      result[:agents].each do |entry|
        expect(entry[:empathy_label]).to be_a(Symbol)
      end
    end

    it 'returns empty when no agents' do
      fresh_engine = Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEngine.new
      result = host.resonance_summary(engine: fresh_engine)
      expect(result[:total]).to eq(0)
      expect(result[:agents]).to be_empty
    end
  end
end
