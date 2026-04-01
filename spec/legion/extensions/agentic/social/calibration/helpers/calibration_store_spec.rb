# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Calibration::Helpers::CalibrationStore do
  subject(:store) { described_class.new }

  let(:constants) { Legion::Extensions::Agentic::Social::Calibration::Helpers::Constants }

  describe '#initialize' do
    it 'starts with neutral weights for all advisory types' do
      expect(store.weights.size).to eq(5)
      store.weights.each_value { |v| expect(v).to eq(0.5) }
    end

    it 'starts clean' do
      expect(store).not_to be_dirty
    end

    it 'starts with empty history' do
      expect(store.history).to be_empty
    end
  end

  describe '#dirty? and #mark_clean!' do
    it 'becomes dirty after evaluation' do
      store.record_advisory(advisory_id: 'test', advisory_types: [:tone_adjustment])
      store.evaluate_reaction(observation: { content: 'thanks', direct_address: true, content_length: 50 })
      expect(store).to be_dirty
    end

    it 'returns self from mark_clean!' do
      expect(store.mark_clean!).to eq(store)
    end

    it 'is clean after mark_clean!' do
      store.record_advisory(advisory_id: 'test', advisory_types: [:tone_adjustment])
      store.evaluate_reaction(observation: { content: 'thanks' })
      store.mark_clean!
      expect(store).not_to be_dirty
    end
  end

  describe '#record_advisory' do
    it 'stores advisory metadata for next evaluation' do
      store.record_advisory(advisory_id: 'abc', advisory_types: %i[tone_adjustment verbosity_adjustment])
      result = store.evaluate_reaction(observation: { content: 'thanks' })
      expect(result).not_to be_nil
      expect(result[:deltas].size).to eq(2)
    end
  end

  describe '#evaluate_reaction' do
    it 'returns nil when no advisory recorded' do
      expect(store.evaluate_reaction(observation: { content: 'hello' })).to be_nil
    end

    it 'returns nil when advisory types are empty' do
      store.record_advisory(advisory_id: 'test', advisory_types: [])
      expect(store.evaluate_reaction(observation: { content: 'hello' })).to be_nil
    end

    context 'with recorded advisory' do
      before { store.record_advisory(advisory_id: 'test', advisory_types: [:tone_adjustment]) }

      it 'produces deltas for positive feedback' do
        result = store.evaluate_reaction(observation: { content: 'thanks, perfect!', direct_address: true, content_length: 20 })
        expect(result[:success]).to be true
        expect(result[:deltas].first[:advisory_type]).to eq('tone_adjustment')
        expect(result[:deltas].first[:new_weight]).to be > 0.5
      end

      it 'produces deltas for negative feedback' do
        result = store.evaluate_reaction(observation: { content: 'no, wrong', content_length: 5 })
        expect(result[:success]).to be true
        expect(result[:deltas].first[:new_weight]).to be < 0.5
      end

      it 'clears advisory meta after evaluation' do
        store.evaluate_reaction(observation: { content: 'ok' })
        expect(store.evaluate_reaction(observation: { content: 'hello' })).to be_nil
      end

      it 'marks store as dirty' do
        store.evaluate_reaction(observation: { content: 'thanks' })
        expect(store).to be_dirty
      end

      it 'records history entry' do
        store.evaluate_reaction(observation: { content: 'thanks' })
        expect(store.history['tone_adjustment']).not_to be_empty
      end
    end
  end

  describe '#detect_explicit_feedback' do
    it 'detects positive' do
      expect(store.detect_explicit_feedback('thanks for that')).to eq(:positive)
      expect(store.detect_explicit_feedback('exactly what I needed')).to eq(:positive)
    end

    it 'detects negative' do
      expect(store.detect_explicit_feedback('no that is wrong')).to eq(:negative)
      expect(store.detect_explicit_feedback("didn't ask for that")).to eq(:negative)
    end

    it 'returns neutral for ambiguous' do
      expect(store.detect_explicit_feedback('I see')).to eq(:neutral)
      expect(store.detect_explicit_feedback('interesting')).to eq(:neutral)
    end
  end

  describe '#calibration_weights' do
    it 'returns a copy' do
      weights = store.calibration_weights
      weights['tone_adjustment'] = 999
      expect(store.calibration_weights['tone_adjustment']).to eq(0.5)
    end
  end

  describe '#update_baseline' do
    it 'initializes baselines on first call' do
      store.update_baseline(latency: 2.0, length: 100)
      entries = store.to_apollo_entries
      weights_entry = entries.find { |e| e[:tags].include?('weights') }
      parsed = Legion::JSON.parse(weights_entry[:content])
      expect(parsed[:baselines][:avg_latency]).to eq(2.0)
    end

    it 'applies EMA on subsequent calls' do
      store.update_baseline(latency: 2.0, length: 100)
      store.update_baseline(latency: 4.0, length: 200)
      entries = store.to_apollo_entries
      weights_entry = entries.find { |e| e[:tags].include?('weights') }
      parsed = Legion::JSON.parse(weights_entry[:content])
      expect(parsed[:baselines][:avg_latency]).to be_between(2.0, 4.0)
    end
  end

  describe '#to_apollo_entries' do
    it 'produces a weights entry with partner tag' do
      entries = store.to_apollo_entries
      weights_entry = entries.find { |e| e[:tags].include?('weights') }
      expect(weights_entry).not_to be_nil
      expect(weights_entry[:tags]).to include('bond', 'calibration', 'weights', 'partner')
    end

    it 'produces history entries after evaluation' do
      store.record_advisory(advisory_id: 'test', advisory_types: [:tone_adjustment])
      store.evaluate_reaction(observation: { content: 'thanks' })
      entries = store.to_apollo_entries
      history_entries = entries.select { |e| e[:tags].include?('history') }
      expect(history_entries).not_to be_empty
    end
  end

  describe '#from_apollo' do
    let(:mock_store) { double('store') }

    it 'restores weights from Apollo Local' do
      content = Legion::JSON.dump({ 'weights' => { 'tone_adjustment' => 0.8 }, 'baselines' => {}, 'updated_at' => Time.now.utc.iso8601 })
      allow(mock_store).to receive(:query).and_return({ success: true, results: [{ content: content, confidence: 0.9 }] })
      expect(store.from_apollo(store: mock_store)).to be true
      expect(store.weights['tone_adjustment']).to eq(0.8)
    end

    it 'returns false when no data' do
      allow(mock_store).to receive(:query).and_return({ success: true, results: [] })
      expect(store.from_apollo(store: mock_store)).to be false
    end

    it 'returns false on error' do
      allow(mock_store).to receive(:query).and_raise(StandardError, 'boom')
      expect(store.from_apollo(store: mock_store)).to be false
    end
  end
end
