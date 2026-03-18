# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::MirrorSystem::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::Mirror' do
    expect(described_class.ancestors).to include(Legion::Extensions::Agentic::Social::MirrorSystem::Runners::Mirror)
  end

  it 'responds to all runner methods' do
    expect(client).to respond_to(:observe_behavior, :imitate_behavior, :report_imitation_outcome)
    expect(client).to respond_to(:strongest_mirrors, :observations_for, :observations_in)
    expect(client).to respond_to(:repertoire_status, :update_mirror, :mirror_stats)
  end

  it 'supports full mirror lifecycle' do
    # Observe another agent deploying successfully
    client.observe_behavior(agent_id: 'expert', action: :canary_deploy, domain: :production, outcome: :success)
    client.observe_behavior(agent_id: 'expert', action: :canary_deploy, domain: :production, outcome: :success)

    # Imitate the behavior
    result = client.imitate_behavior(action: :canary_deploy, domain: :production)
    expect(result[:imitated]).to be true
    expect(result[:source]).to eq('expert')

    # Report outcome
    client.report_imitation_outcome(action: :canary_deploy, domain: :production, success_flag: true)

    # Check repertoire
    rep = client.repertoire_status
    expect(rep[:size]).to eq(1)

    # Tick
    client.update_mirror

    # Stats
    stats = client.mirror_stats
    expect(stats[:stats][:mirrored_agents]).to eq(1)
  end
end
