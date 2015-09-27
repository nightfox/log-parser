class LogParser
  module MeanHelper

    extend ::ActiveSupport::Concern

    included do |base|

      def set_mean_data(data)
        storage = self.local_storage[self.current_line_type]
        storage[:count] += 1
        storage[:total_time] += (data[:connect] + data[:service])

        nil
      end

      def calculate_mean(total, count)
        return 0 if count == 0

        (total.to_f / count).round(2)
      end

      def print_mean(total, count)
        "mean=#{calculate_mean(total, count)}ms"
      end
    end
  end
end