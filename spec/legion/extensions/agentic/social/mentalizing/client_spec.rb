# frozen_string_literal: true

require 'legion/extensions/agentic/social/mentalizing/client'

RSpec.describe Legion::Extensions::Agentic::Social::Mentalizing::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:attribute_belief)
    expect(client).to respond_to(:project_belief)
    expect(client).to respond_to(:check_alignment)
    expect(client).to respond_to(:detect_false_belief)
    expect(client).to respond_to(:beliefs_for_agent)
    expect(client).to respond_to(:beliefs_about_agent)
    expect(client).to respond_to(:recursive_belief_lookup)
    expect(client).to respond_to(:update_mentalizing)
    expect(client).to respond_to(:mentalizing_stats)
  end
end
