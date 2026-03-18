# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Helpers::Simulation do
  let(:event_id) { 'event-uuid-001' }
  let(:outcome)  { { action_type: :communication, predicted_intent: :inform_or_persuade } }

  subject(:sim) do
    described_class.new(
      event_id:            event_id,
      simulated_outcome:   outcome,
      confidence:          0.7,
      emotional_resonance: 0.6
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(sim.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns event_id' do
      expect(sim.event_id).to eq(event_id)
    end

    it 'assigns simulated_outcome' do
      expect(sim.simulated_outcome).to eq(outcome)
    end

    it 'clamps confidence to [0, 1]' do
      s = described_class.new(event_id: 'x', simulated_outcome: {}, confidence: 1.5)
      expect(s.confidence).to eq(1.0)
    end

    it 'clamps emotional_resonance to [0, 1]' do
      s = described_class.new(event_id: 'x', simulated_outcome: {}, emotional_resonance: -0.3)
      expect(s.emotional_resonance).to eq(0.0)
    end

    it 'defaults accuracy_score to nil' do
      expect(sim.accuracy_score).to be_nil
    end

    it 'assigns simulated_at as a Time' do
      expect(sim.simulated_at).to be_a(Time)
    end

    it 'uses SIMULATION_CONFIDENCE_DEFAULT when confidence not given' do
      s = described_class.new(event_id: 'x', simulated_outcome: {})
      expect(s.confidence).to eq(
        Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::SIMULATION_CONFIDENCE_DEFAULT
      )
    end

    it 'uses DEFAULT_RESONANCE when emotional_resonance not given' do
      s = described_class.new(event_id: 'x', simulated_outcome: {})
      expect(s.emotional_resonance).to eq(
        Legion::Extensions::Agentic::Social::Mirror::Helpers::Constants::DEFAULT_RESONANCE
      )
    end
  end

  describe '#accuracy_score=' do
    it 'allows setting accuracy_score' do
      sim.accuracy_score = 0.85
      expect(sim.accuracy_score).to eq(0.85)
    end
  end

  describe '#to_h' do
    subject(:hash) { sim.to_h }

    it 'includes id' do
      expect(hash[:id]).to eq(sim.id)
    end

    it 'includes event_id' do
      expect(hash[:event_id]).to eq(event_id)
    end

    it 'includes simulated_outcome' do
      expect(hash[:simulated_outcome]).to eq(outcome)
    end

    it 'includes confidence' do
      expect(hash[:confidence]).to eq(0.7)
    end

    it 'includes emotional_resonance' do
      expect(hash[:emotional_resonance]).to eq(0.6)
    end

    it 'includes simulated_at' do
      expect(hash[:simulated_at]).to be_a(Time)
    end

    it 'includes accuracy_score as nil initially' do
      expect(hash[:accuracy_score]).to be_nil
    end
  end
end
