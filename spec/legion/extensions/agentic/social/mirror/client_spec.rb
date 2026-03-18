# frozen_string_literal: true

require 'legion/extensions/agentic/social/mirror/client'

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Client do
  subject(:client) { described_class.new }

  it 'responds to observe runner methods' do
    expect(client).to respond_to(:observe_action)
    expect(client).to respond_to(:list_events)
  end

  it 'responds to simulate runner methods' do
    expect(client).to respond_to(:simulate_action)
    expect(client).to respond_to(:record_simulation_accuracy)
    expect(client).to respond_to(:simulation_history)
  end

  it 'responds to resonance runner methods' do
    expect(client).to respond_to(:empathic_resonance)
    expect(client).to respond_to(:decay_resonances)
    expect(client).to respond_to(:resonance_summary)
  end

  it 'shares a single internal engine across all runners' do
    client.observe_action(agent_id: 'agent-1', action_type: :communication)
    result = client.list_events(agent_id: 'agent-1')
    expect(result[:count]).to eq(1)
  end

  it 'performs a full observe -> simulate -> resonance cycle' do
    obs_result = client.observe_action(
      agent_id:          'agent-1',
      action_type:       :decision,
      emotional_valence: 0.6
    )
    expect(obs_result[:success]).to be(true)

    event_id = obs_result[:event][:id]
    sim_result = client.simulate_action(event_id: event_id, confidence: 0.75)
    expect(sim_result[:success]).to be(true)
    expect(sim_result[:simulation][:confidence]).to eq(0.75)

    res_result = client.empathic_resonance(agent_id: 'agent-1')
    expect(res_result[:resonance]).to be > 0.5
  end

  it 'records accuracy and returns it in subsequent queries' do
    obs = client.observe_action(agent_id: 'agent-2', action_type: :analytical_task)
    sim_result = client.simulate_action(event_id: obs[:event][:id])
    sim_id = sim_result[:simulation][:id]

    client.record_simulation_accuracy(simulation_id: sim_id, accuracy: 0.9)

    res = client.empathic_resonance(agent_id: 'agent-2')
    expect(res[:accuracy]).to be_within(0.001).of(0.9)
  end

  it 'global decay lowers resonance for all agents' do
    client.observe_action(agent_id: 'agent-a', action_type: :movement)
    client.observe_action(agent_id: 'agent-b', action_type: :social_interaction)

    # Boost by simulating
    list_a = client.list_events(agent_id: 'agent-a')
    list_b = client.list_events(agent_id: 'agent-b')
    client.simulate_action(event_id: list_a[:events].first[:id])
    client.simulate_action(event_id: list_b[:events].first[:id])

    before_a = client.empathic_resonance(agent_id: 'agent-a')[:resonance]
    before_b = client.empathic_resonance(agent_id: 'agent-b')[:resonance]

    client.decay_resonances

    after_a = client.empathic_resonance(agent_id: 'agent-a')[:resonance]
    after_b = client.empathic_resonance(agent_id: 'agent-b')[:resonance]

    expect(after_a).to be < before_a
    expect(after_b).to be < before_b
  end

  it 'resonance_summary shows all agents after observations' do
    client.observe_action(agent_id: 'agent-x', action_type: :creative_act)
    e = client.list_events(agent_id: 'agent-x')
    client.simulate_action(event_id: e[:events].first[:id])

    summary = client.resonance_summary
    expect(summary[:total]).to be >= 1
    agent_entry = summary[:agents].find { |a| a[:agent_id] == 'agent-x' }
    expect(agent_entry).not_to be_nil
    expect(agent_entry[:empathy_label]).to be_a(Symbol)
  end
end
