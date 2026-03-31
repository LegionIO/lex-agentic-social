# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Social
        module Attachment
          module Helpers
            class AttachmentStore
              def initialize
                @models = {}
                @dirty  = false
              end

              def get(agent_id)
                @models[agent_id.to_s]
              end

              def get_or_create(agent_id)
                key = agent_id.to_s
                @models[key] ||= begin
                  @dirty = true
                  AttachmentModel.new(agent_id: key)
                end
              end

              def all_models
                @models.values
              end

              def dirty?
                @dirty
              end

              def mark_clean!
                @dirty = false
                self
              end

              def to_apollo_entries
                @models.map do |agent_id, model|
                  tags = Constants::TAG_PREFIX.dup + [agent_id]
                  tags << 'partner' if partner?(agent_id)
                  content = serialize(model.to_h)
                  { content: content, tags: tags }
                end
              end

              def from_apollo(store:)
                result = store.query(text: 'bond attachment', tags: %w[bond attachment])
                return false unless result[:success] && result[:results]&.any?

                result[:results].each do |entry|
                  parsed = deserialize(entry[:content])
                  next unless parsed && parsed[:agent_id]

                  @models[parsed[:agent_id].to_s] = AttachmentModel.from_h(parsed)
                end
                true
              rescue StandardError => e
                warn "[attachment_store] from_apollo error: #{e.message}"
                false
              end

              private

              def partner?(agent_id)
                defined?(Legion::Gaia::BondRegistry) && Legion::Gaia::BondRegistry.partner?(agent_id)
              end

              def serialize(hash)
                defined?(Legion::JSON) ? Legion::JSON.dump(hash) : ::JSON.dump(hash)
              end

              def deserialize(content)
                parsed = defined?(Legion::JSON) ? Legion::JSON.parse(content) : ::JSON.parse(content, symbolize_names: true)
                parsed.transform_keys(&:to_sym)
              rescue StandardError => _e
                nil
              end
            end
          end
        end
      end
    end
  end
end
