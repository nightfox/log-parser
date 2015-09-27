class LogParser
  module ModeHelper

    extend ::ActiveSupport::Concern

    included do |base|

      def set_mode_data(data)
        storage = self.local_storage[self.current_line_type]
        storage[:dyno_frequency_hash][data[:dyno]] ||= 0
        storage[:dyno_frequency_hash][data[:dyno]] += 1

        total = data[:connect] + data[:service]
        storage[:response_frequency_hash][total] ||= 0
        storage[:response_frequency_hash][total] += 1

        nil
      end

      def print_frequency_mode(key)
        storage = self.local_storage[key]

        return 'mode_for_response=none' if storage[:response_frequency_hash].length == 0

        sorted = storage[:response_frequency_hash].sort_by { |key, value| -value }
        keys = [sorted.first.first]
        values = [sorted.first.last]
        val = sorted.first.last
        index = 1


        while sorted[index] && sorted[index][1] >= val
          keys << sorted[index][0]
          values << sorted[index][1]
          index += 1
        end

        "mode_for_response=#{keys.map { |k| "#{k}ms" }.join(', ')}"
      end

      def print_dyno_mode(key)
        storage = self.local_storage[key]

        return 'most_hit_dyno=none' if storage[:dyno_frequency_hash].length == 0

        sorted = storage[:dyno_frequency_hash].sort_by { |key, value| -value }
        keys = [sorted.first.first]
        val = sorted.first.last

        index = 1

        while sorted[index] && sorted[index][1] >= val
          keys << sorted[index][0]
          index += 1
        end

        "most_hit_dyno=#{keys.join(', ')}"
      end
    end
  end
end