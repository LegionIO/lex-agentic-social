# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Entrainment::Client do
  subject(:client) { described_class.new }

  it 'creates a pairing and records interaction' do
    created = client.create_entrainment_pairing(
      agent_a: 'alpha', agent_b: 'beta', domain: :reasoning
    )
    result = client.record_entrainment_interaction(
      pairing_id: created[:pairing_id], aligned: true
    )
    expect(result[:success]).to be true
    expect(result[:synchrony]).to be > 0.0
  end

  it 'returns stats' do
    result = client.cognitive_entrainment_stats
    expect(result[:success]).to be true
  end
end
