# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Calibration
          module Helpers
            module Constants
              ADVISORY_TYPES = %i[
                tone_adjustment
                verbosity_adjustment
                format_adjustment
                context_injection
                partner_hint
              ].freeze

              EMA_ALPHA = 0.1
              NEUTRAL_SCORE = 0.5
              SUPPRESSION_THRESHOLD = 0.4
              HIGH_CALIBRATION = 0.7
              MAX_HISTORY = 50

              TAG_PREFIX = %w[bond calibration].freeze
              WEIGHTS_TAGS = (TAG_PREFIX + ['weights']).freeze
              HISTORY_TAG_PREFIX = (TAG_PREFIX + ['history']).freeze

              POSITIVE_PATTERNS = /\b(thanks|perfect|exactly|great|good|helpful|nice|yes)\b/i
              NEGATIVE_PATTERNS = /\b(no|wrong|not what|stop|don't|didn't ask|incorrect)\b/i

              SIGNAL_WEIGHTS = {
                explicit_feedback: 0.35,
                response_latency:  0.20,
                message_length:    0.15,
                direct_address:    0.15,
                continuation:      0.15
              }.freeze

              PROMOTABLE_TAGS = [
                %w[bond attachment],
                %w[bond communication_pattern],
                %w[bond calibration weights],
                %w[partner preference]
              ].freeze

              PROMOTION_MIN_CONFIDENCE = 0.6
              PREFERENCE_EXTRACTION_INTERVAL = 604_800 # 7 days

              module_function

              def advisory_type?(type)
                ADVISORY_TYPES.include?(type.to_sym)
              end

              def suppressed?(score)
                score < SUPPRESSION_THRESHOLD
              end
            end
          end
        end
      end
    end
  end
end
