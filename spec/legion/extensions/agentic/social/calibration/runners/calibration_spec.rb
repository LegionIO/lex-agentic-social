# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Calibration::Runners::Calibration do
  let(:client) { Legion::Extensions::Agentic::Social::Calibration::Client.new }

  describe '#update_calibration' do
    it 'skips when no observation' do
      result = client.update_calibration
      expect(result[:skipped]).to eq(:no_observation)
    end

    it 'skips when no advisory recorded' do
      result = client.update_calibration(observation: { content: 'hi', content_length: 2 })
      expect(result[:skipped]).to eq(:no_advisory)
    end

    it 'produces deltas when advisory recorded' do
      client.record_advisory_meta(advisory_id: 'test', advisory_types: [:tone_adjustment])
      result = client.update_calibration(observation: { content: 'thanks', direct_address: true, content_length: 20 })
      expect(result[:success]).to be true
      expect(result[:deltas]).not_to be_empty
    end
  end

  describe '#record_advisory_meta' do
    it 'succeeds' do
      result = client.record_advisory_meta(advisory_id: 'abc', advisory_types: [:partner_hint])
      expect(result[:success]).to be true
    end
  end

  describe '#detect_explicit_feedback' do
    it 'returns positive for thanks' do
      result = client.detect_explicit_feedback(content: 'thanks!')
      expect(result[:feedback]).to eq(:positive)
    end

    it 'returns negative for wrong' do
      result = client.detect_explicit_feedback(content: 'wrong answer')
      expect(result[:feedback]).to eq(:negative)
    end

    it 'returns neutral for ambiguous' do
      result = client.detect_explicit_feedback(content: 'okay')
      expect(result[:feedback]).to eq(:neutral)
    end
  end

  describe '#calibration_weights' do
    it 'returns all advisory types' do
      result = client.calibration_weights
      expect(result[:weights].keys.size).to eq(5)
    end
  end

  describe '#calibration_stats' do
    it 'returns stats hash' do
      result = client.calibration_stats
      expect(result[:success]).to be true
      expect(result).to have_key(:weights)
      expect(result).to have_key(:history_counts)
      expect(result).to have_key(:dirty)
    end
  end

  describe '#extract_preferences_via_llm' do
    it 'skips when LLM unavailable' do
      result = client.extract_preferences_via_llm
      expect(result[:skipped]).to eq(:llm_unavailable)
    end
  end

  describe '#retrieve_from_memory' do
    it 'returns empty array when lex-agentic-memory is not loaded' do
      result = client.send(:retrieve_from_memory)
      expect(result).to eq([])
    end
  end

  describe '#retrieve_from_apollo_local' do
    it 'returns empty array when Apollo Local is not available' do
      result = client.send(:retrieve_from_apollo_local)
      expect(result).to eq([])
    end

    it 'maps Apollo Local entries to trace-compatible hashes when available' do
      mock_local = double('apollo_local')
      stub_const('Legion::Apollo', Module.new)
      stub_const('Legion::Apollo::Local', mock_local)
      allow(mock_local).to receive(:started?).and_return(true)
      allow(mock_local).to receive(:query_by_tags).with(tags: ['partner_interaction'], limit: 50).and_return([
                                                                                                               {
                                                                                                                 content:    'hello partner',
                                                                                                                 tags:       ['partner_interaction'],
                                                                                                                 confidence: 0.8
                                                                                                               }
                                                                                                             ])

      result = client.send(:retrieve_from_apollo_local)
      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:content]).to eq('hello partner')
      expect(result.first[:confidence]).to eq(0.8)
    end

    it 'returns empty array and logs warning when Apollo Local raises' do
      mock_local = double('apollo_local')
      stub_const('Legion::Apollo', Module.new)
      stub_const('Legion::Apollo::Local', mock_local)
      allow(mock_local).to receive(:started?).and_return(true)
      allow(mock_local).to receive(:query_by_tags).and_raise(StandardError, 'db error')
      allow(Legion::Logging).to receive(:warn)

      result = client.send(:retrieve_from_apollo_local)
      expect(result).to eq([])
      expect(Legion::Logging).to have_received(:warn).with(a_string_including('retrieve_from_apollo_local'))
    end
  end

  describe '#retrieve_interaction_traces' do
    it 'falls through to Apollo Local when memory returns no traces' do
      allow(client).to receive(:retrieve_from_memory).and_return([])
      allow(client).to receive(:retrieve_from_apollo_local).and_return([{ content: 'trace', tags: [], confidence: 0.5 }])

      result = client.send(:retrieve_interaction_traces)
      expect(result).not_to be_empty
      expect(result.first[:content]).to eq('trace')
    end

    it 'returns memory traces directly without calling Apollo Local when memory has results' do
      memory_trace = { content: 'memory trace', tags: ['partner_interaction'], recorded_at: Time.now }
      allow(client).to receive(:retrieve_from_memory).and_return([memory_trace])
      expect(client).not_to receive(:retrieve_from_apollo_local)

      result = client.send(:retrieve_interaction_traces)
      expect(result).to eq([memory_trace])
    end
  end

  describe '#promote_partner_knowledge' do
    it 'skips when Apollo Local unavailable' do
      result = client.promote_partner_knowledge
      expect(result[:skipped]).to eq(:local_unavailable)
    end
  end

  describe '#sync_partner_knowledge' do
    it 'returns combined results' do
      result = client.sync_partner_knowledge
      expect(result[:success]).to be true
      expect(result[:results]).to have_key(:preferences)
      expect(result[:results]).to have_key(:promotion)
    end
  end
end
