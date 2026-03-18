# frozen_string_literal: true

require 'legion/extensions/agentic/social/conflict/client'

RSpec.describe Legion::Extensions::Agentic::Social::Conflict::Client do
  it 'responds to conflict runner methods' do
    client = described_class.new
    expect(client).to respond_to(:register_conflict)
    expect(client).to respond_to(:add_exchange)
    expect(client).to respond_to(:resolve_conflict)
    expect(client).to respond_to(:get_conflict)
    expect(client).to respond_to(:active_conflicts)
    expect(client).to respond_to(:recommended_posture)
  end
end
