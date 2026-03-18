# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Runners::Simulate do
  let(:engine) { Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEngine.new }

  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  let(:event) do
    engine.observe(agent_id: 'agent-1', action_type: :communication, emotional_valence: 0.5)
  end

  describe '#simulate_action' do
    it 'returns success: true for known event_id' do
      result = host.simulate_action(event_id: event.id, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns simulation hash' do
      result = host.simulate_action(event_id: event.id, engine: engine)
      expect(result[:simulation]).to be_a(Hash)
      expect(result[:simulation][:event_id]).to eq(event.id)
    end

    it 'returns a confidence_tier symbol' do
      result = host.simulate_action(event_id: event.id, engine: engine)
      expect(result[:confidence_tier]).to be_a(Symbol)
    end

    it 'returns success: false for unknown event_id' do
      result = host.simulate_action(event_id: 'nonexistent', engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to eq('event not found')
    end

    it 'respects provided confidence' do
      result = host.simulate_action(event_id: event.id, confidence: 0.9, engine: engine)
      expect(result[:simulation][:confidence]).to eq(0.9)
    end

    it 'boosts agent resonance after simulation' do
      before = engine.empathic_resonance('agent-1')
      host.simulate_action(event_id: event.id, engine: engine)
      expect(engine.empathic_resonance('agent-1')).to be > before
    end
  end

  describe '#record_simulation_accuracy' do
    let(:sim) { engine.simulate(event) }

    it 'returns success: true when simulation found' do
      result = host.record_simulation_accuracy(simulation_id: sim.id, accuracy: 0.8, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'records the accuracy value' do
      host.record_simulation_accuracy(simulation_id: sim.id, accuracy: 0.75, engine: engine)
      expect(sim.accuracy_score).to eq(0.75)
    end

    it 'returns success: false for unknown simulation' do
      result = host.record_simulation_accuracy(simulation_id: 'nope', accuracy: 0.5, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to eq('simulation not found')
    end

    it 'clamps accuracy to [0, 1]' do
      result = host.record_simulation_accuracy(simulation_id: sim.id, accuracy: 1.5, engine: engine)
      expect(result[:accuracy]).to eq(1.0)
    end
  end

  describe '#simulation_history' do
    before do
      3.times do
        e = engine.observe(agent_id: 'agent-1', action_type: :decision)
        engine.simulate(e)
      end
    end

    it 'returns success: true' do
      expect(host.simulation_history(engine: engine)[:success]).to be(true)
    end

    it 'returns simulation hashes' do
      result = host.simulation_history(engine: engine)
      expect(result[:simulations]).to all(be_a(Hash))
    end

    it 'respects limit parameter' do
      result = host.simulation_history(limit: 2, engine: engine)
      expect(result[:count]).to eq(2)
    end

    it 'returns all when limit exceeds available' do
      result = host.simulation_history(limit: 100, engine: engine)
      expect(result[:count]).to eq(3)
    end
  end
end
