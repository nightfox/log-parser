class LogParser
  module MedianHelper

    extend ::ActiveSupport::Concern

    included do |base|

      def set_median_data(data)
        storage = self.local_storage[self.current_line_type]
        min_heap_size = storage[:min_heap].size
        max_heap_size = storage[:max_heap].size
        signature = max_heap_size <=> min_heap_size
        total = data[:connect] + data[:service]

        case signature
          when 1
            if total < storage[:median]
              storage[:min_heap] << storage[:max_heap].pop
              storage[:max_heap] << total
            else
              storage[:min_heap] << total
            end
            storage[:median] = (storage[:min_heap].min + storage[:max_heap].max).to_f / 2
          when 0
            if total < storage[:median]
              storage[:max_heap] << total
              storage[:median] = storage[:max_heap].max
            else
              storage[:min_heap] << total
              storage[:median] = storage[:min_heap].min
            end
          when -1
            if total < storage[:median]
              storage[:max_heap] << total
            else
              storage[:max_heap] << storage[:min_heap].min
              storage[:min_heap] << total
            end

            storage[:median] = (storage[:min_heap].min + storage[:max_heap].max).to_f / 2
        end

      end

      def print_median(median)
        "median=#{median.to_i}ms"
      end
    end
  end
end
