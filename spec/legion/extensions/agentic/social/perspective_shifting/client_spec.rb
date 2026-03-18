# frozen_string_literal: true

require 'legion/extensions/agentic/social/perspective_shifting/client'

RSpec.describe Legion::Extensions::Agentic::Social::PerspectiveShifting::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:add_perspective)
    expect(client).to respond_to(:list_perspectives)
    expect(client).to respond_to(:get_perspective)
    expect(client).to respond_to(:add_situation)
    expect(client).to respond_to(:list_situations)
    expect(client).to respond_to(:generate_view)
    expect(client).to respond_to(:views_for_situation)
    expect(client).to respond_to(:perspective_agreement)
    expect(client).to respond_to(:blind_spots)
    expect(client).to respond_to(:coverage_score)
    expect(client).to respond_to(:dominant_view)
    expect(client).to respond_to(:synthesize)
    expect(client).to respond_to(:most_divergent_pair)
    expect(client).to respond_to(:engine_status)
  end

  it 'initializes with its own isolated engine per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.add_perspective(name: 'CEO', type: :stakeholder)
    expect(c2.list_perspectives[:count]).to eq(0)
  end
end
