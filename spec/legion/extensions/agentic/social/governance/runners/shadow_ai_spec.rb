# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Agentic::Social::Governance::Runners::ShadowAi do
  let(:host) { Object.new.extend(described_class) }

  describe '#check_llm_bypass_indicators' do
    it 'detects direct API key when provider not enabled' do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with('OPENAI_API_KEY').and_return(true)
      allow(ENV).to receive(:key?).with('ANTHROPIC_API_KEY').and_return(false)
      allow(Legion::Settings).to receive(:[]).with(:llm).and_return(
        { providers: { openai: { enabled: false } } }
      )
      result = host.check_llm_bypass_indicators
      expect(result[:bypassed]).to be true
      expect(result[:indicators]).to include(:direct_openai_key)
    end

    it 'returns clean when no bypass indicators' do
      allow(ENV).to receive(:key?).with('OPENAI_API_KEY').and_return(false)
      allow(ENV).to receive(:key?).with('ANTHROPIC_API_KEY').and_return(false)
      result = host.check_llm_bypass_indicators
      expect(result[:bypassed]).to be false
      expect(result[:indicators]).to be_empty
    end

    it 'does not flag when provider is enabled' do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:key?).with('OPENAI_API_KEY').and_return(true)
      allow(ENV).to receive(:key?).with('ANTHROPIC_API_KEY').and_return(false)
      allow(Legion::Settings).to receive(:[]).with(:llm).and_return(
        { providers: { openai: { enabled: true } } }
      )
      result = host.check_llm_bypass_indicators
      expect(result[:bypassed]).to be false
    end
  end

  describe '#check_airb_compliance' do
    it 'returns unavailable when data model not loaded' do
      result = host.check_airb_compliance
      expect(result[:source]).to eq(:unavailable)
    end
  end

  describe '#full_scan' do
    it 'returns combined results' do
      allow(host).to receive(:scan_unregistered_extensions).and_return(
        { installed: 5, registered: 5, unregistered: [] }
      )
      allow(host).to receive(:check_llm_bypass_indicators).and_return(
        { indicators: [], bypassed: false }
      )
      allow(host).to receive(:check_airb_compliance).and_return(
        { checked: 0, source: :unavailable }
      )

      result = host.full_scan
      expect(result[:issues_found]).to be_falsey
      expect(result[:extensions][:installed]).to eq(5)
    end
  end
end
