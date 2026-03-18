# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MoralReasoning::Client do
  subject(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:evaluate_moral_action)
    expect(client).to respond_to(:pose_moral_dilemma)
    expect(client).to respond_to(:resolve_moral_dilemma)
    expect(client).to respond_to(:apply_ethical_framework)
    expect(client).to respond_to(:add_moral_principle)
    expect(client).to respond_to(:check_moral_development)
    expect(client).to respond_to(:moral_foundation_profile)
    expect(client).to respond_to(:moral_stage_info)
    expect(client).to respond_to(:update_moral_reasoning)
    expect(client).to respond_to(:moral_reasoning_stats)
  end

  it 'maintains separate engine state per instance' do
    client_a = described_class.new
    client_b = described_class.new

    client_a.pose_moral_dilemma(
      description: 'Instance A dilemma',
      options:     [{ id: 'opt_a', description: 'Option A', foundations: [:care] }]
    )

    stats_a = client_a.moral_reasoning_stats
    stats_b = client_b.moral_reasoning_stats

    expect(stats_a[:total_dilemmas]).to eq(1)
    expect(stats_b[:total_dilemmas]).to eq(0)
  end
end
