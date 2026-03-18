# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEngine do
  subject(:engine) { described_class.new }

  let(:agent_id) { 'agent-alpha' }

  def observe_event(action_type: :communication, valence: 0.5)
    engine.observe(agent_id: agent_id, action_type: action_type, emotional_valence: valence)
  end

  describe '#initialize' do
    it 'starts with empty events' do
      expect(engine.events).to be_empty
    end

    it 'starts with empty simulations' do
      expect(engine.simulations).to be_empty
    end

    it 'returns DEFAULT_RESONANCE for unknown agents' do
      expect(engine.empathic_resonance('unknown-agent')).to eq(
        Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::DEFAULT_RESONANCE
      )
    end
  end

  describe '#observe' do
    it 'creates and stores a MirrorEvent' do
      event = observe_event
      expect(engine.events).to include(event)
    end

    it 'returns a MirrorEvent instance' do
      expect(observe_event).to be_a(Legion::Extensions::Agentic::Social::Mirror::Helpers::MirrorEvent)
    end

    it 'caps events at MAX_EVENTS' do
      max = Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::MAX_EVENTS
      (max + 5).times { observe_event }
      expect(engine.events.size).to eq(max)
    end
  end

  describe '#simulate' do
    let(:event) { observe_event }

    it 'returns a Simulation instance' do
      sim = engine.simulate(event)
      expect(sim).to be_a(Legion::Extensions::Agentic::Social::Mirror::Helpers::Simulation)
    end

    it 'links simulation to the event via event_id' do
      sim = engine.simulate(event)
      expect(sim.event_id).to eq(event.id)
    end

    it 'stores the simulation' do
      sim = engine.simulate(event)
      expect(engine.simulations).to include(sim)
    end

    it 'caps simulations at MAX_SIMULATIONS' do
      max = Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::MAX_SIMULATIONS
      (max + 5).times do
        e = observe_event
        engine.simulate(e)
      end
      expect(engine.simulations.size).to eq(max)
    end

    it 'uses provided confidence' do
      sim = engine.simulate(event, confidence: 0.8)
      expect(sim.confidence).to eq(0.8)
    end
  end

  describe '#record_accuracy' do
    it 'sets accuracy_score on the simulation' do
      event = observe_event
      sim   = engine.simulate(event)
      engine.record_accuracy(sim.id, 0.9)
      expect(sim.accuracy_score).to eq(0.9)
    end

    it 'returns true when simulation found' do
      event = observe_event
      sim   = engine.simulate(event)
      expect(engine.record_accuracy(sim.id, 0.5)).to be(true)
    end

    it 'returns false when simulation not found' do
      expect(engine.record_accuracy('nonexistent-id', 0.5)).to be(false)
    end

    it 'clamps accuracy to [0, 1]' do
      event = observe_event
      sim   = engine.simulate(event)
      engine.record_accuracy(sim.id, 1.5)
      expect(sim.accuracy_score).to eq(1.0)
    end
  end

  describe '#empathic_resonance' do
    it 'returns DEFAULT_RESONANCE for new agents' do
      expect(engine.empathic_resonance('new-agent')).to eq(0.5)
    end

    it 'reflects boosted resonance after boost_resonance' do
      engine.boost_resonance(agent_id)
      expect(engine.empathic_resonance(agent_id)).to be > 0.5
    end
  end

  describe '#boost_resonance' do
    it 'increases resonance by RESONANCE_BOOST' do
      engine.boost_resonance(agent_id)
      expected = (0.5 + Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::RESONANCE_BOOST).round(10)
      expect(engine.empathic_resonance(agent_id)).to be_within(0.0001).of(expected)
    end

    it 'does not exceed 1.0' do
      10.times { engine.boost_resonance(agent_id) }
      expect(engine.empathic_resonance(agent_id)).to be <= 1.0
    end
  end

  describe '#decay_resonance' do
    it 'decreases resonance by RESONANCE_DECAY' do
      engine.boost_resonance(agent_id)
      before = engine.empathic_resonance(agent_id)
      engine.decay_resonance(agent_id)
      expect(engine.empathic_resonance(agent_id)).to be < before
    end

    it 'does not go below 0.0' do
      20.times { engine.decay_resonance(agent_id) }
      expect(engine.empathic_resonance(agent_id)).to be >= 0.0
    end
  end

  describe '#decay_all_resonances' do
    it 'decays resonance for all tracked agents' do
      engine.boost_resonance('agent-1')
      engine.boost_resonance('agent-2')
      before_first  = engine.empathic_resonance('agent-1')
      before_second = engine.empathic_resonance('agent-2')
      engine.decay_all_resonances
      expect(engine.empathic_resonance('agent-1')).to be < before_first
      expect(engine.empathic_resonance('agent-2')).to be < before_second
    end
  end

  describe '#simulation_accuracy_for' do
    it 'returns nil when no scored simulations' do
      observe_event
      expect(engine.simulation_accuracy_for(agent_id)).to be_nil
    end

    it 'returns average accuracy when scored' do
      e1 = observe_event
      e2 = observe_event
      s1 = engine.simulate(e1)
      s2 = engine.simulate(e2)
      engine.record_accuracy(s1.id, 0.8)
      engine.record_accuracy(s2.id, 0.6)
      expect(engine.simulation_accuracy_for(agent_id)).to be_within(0.001).of(0.7)
    end
  end

  describe '#events_for' do
    it 'filters events by agent_id' do
      observe_event
      engine.observe(agent_id: 'other-agent', action_type: :movement)
      expect(engine.events_for(agent_id).size).to eq(1)
      expect(engine.events_for('other-agent').size).to eq(1)
    end
  end

  describe '#simulations_for' do
    it 'returns only simulations for a given agent' do
      e = observe_event
      engine.simulate(e)
      other = engine.observe(agent_id: 'other', action_type: :movement)
      engine.simulate(other)
      expect(engine.simulations_for(agent_id).size).to eq(1)
    end
  end

  describe '#simulation_history' do
    it 'returns last N simulations as hashes' do
      3.times do
        e = observe_event
        engine.simulate(e)
      end
      history = engine.simulation_history(limit: 2)
      expect(history.size).to eq(2)
      expect(history.first).to be_a(Hash)
    end

    it 'defaults to 20 entries' do
      25.times do
        e = observe_event
        engine.simulate(e)
      end
      expect(engine.simulation_history.size).to eq(20)
    end
  end

  describe '#known_agents' do
    it 'returns agents with resonance entries' do
      engine.boost_resonance('agent-a')
      engine.boost_resonance('agent-b')
      expect(engine.known_agents).to include('agent-a', 'agent-b')
    end
  end
end
