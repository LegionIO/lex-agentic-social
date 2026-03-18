# frozen_string_literal: true

require 'legion/extensions/agentic/social/apprenticeship/client'

RSpec.describe Legion::Extensions::Agentic::Social::Apprenticeship::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:create_apprenticeship)
    expect(client).to respond_to(:conduct_apprenticeship_session)
    expect(client).to respond_to(:recommend_apprenticeship_method)
    expect(client).to respond_to(:graduated_apprenticeships)
    expect(client).to respond_to(:active_apprenticeships)
    expect(client).to respond_to(:mentor_apprenticeships)
    expect(client).to respond_to(:apprentice_apprenticeships)
    expect(client).to respond_to(:domain_apprenticeships)
    expect(client).to respond_to(:update_cognitive_apprenticeship)
    expect(client).to respond_to(:cognitive_apprenticeship_stats)
  end
end
