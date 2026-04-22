# frozen_string_literal: true

# Stub the framework actor base class since legionio gem is not available in test
unless defined?(Legion::Extensions::Actors::Every)
  module Legion
    module Extensions
      module Actors
        class Every # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end
end

# Intercept the require in the actor file so it doesn't fail
$LOADED_FEATURES << 'legion/extensions/actors/every' unless $LOADED_FEATURES.include?('legion/extensions/actors/every')

require 'legion/extensions/agentic/social/mirror/actors/resonance_decay'

RSpec.describe Legion::Extensions::Agentic::Social::Mirror::Actor::ResonanceDecay do
  subject(:actor) { described_class.new }

  describe '#runner_class' do
    it 'returns Mirror::Client' do
      expect(actor.runner_class).to eq(Legion::Extensions::Agentic::Social::Mirror::Client)
    end
  end

  describe '#runner_function' do
    it 'returns decay_resonances' do
      expect(actor.runner_function).to eq('decay_resonances')
    end
  end

  describe '#time' do
    it 'returns 120 seconds' do
      expect(actor.time).to eq(120)
    end
  end

  describe '#run_now?' do
    it 'returns false' do
      expect(actor.run_now?).to be false
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
