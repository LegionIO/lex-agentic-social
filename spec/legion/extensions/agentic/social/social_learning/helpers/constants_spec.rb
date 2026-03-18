# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::SocialLearning::Helpers::Constants do
  it 'defines MAX_MODELS' do
    expect(described_module::MAX_MODELS).to eq(200)
  end

  it 'defines MAX_BEHAVIORS' do
    expect(described_module::MAX_BEHAVIORS).to eq(500)
  end

  it 'defines ATTENTION_THRESHOLD' do
    expect(described_module::ATTENTION_THRESHOLD).to eq(0.3)
  end

  it 'defines REPRODUCTION_CONFIDENCE' do
    expect(described_module::REPRODUCTION_CONFIDENCE).to eq(0.5)
  end

  it 'defines OUTCOME_TYPES' do
    expect(described_module::OUTCOME_TYPES).to eq(%i[positive negative neutral])
  end

  it 'defines LEARNING_STAGES' do
    expect(described_module::LEARNING_STAGES).to eq(%i[attention retention reproduction motivation])
  end

  it 'defines MODEL_LABELS mapping' do
    expect(described_module::MODEL_LABELS).to be_a(Hash)
    expect(described_module::MODEL_LABELS.size).to eq(5)
  end

  it 'PRESTIGE_FLOOR is 0.0' do
    expect(described_module::PRESTIGE_FLOOR).to eq(0.0)
  end

  it 'PRESTIGE_CEILING is 1.0' do
    expect(described_module::PRESTIGE_CEILING).to eq(1.0)
  end

  def described_module
    Legion::Extensions::Agentic::Social::SocialLearning::Helpers::Constants
  end
end
