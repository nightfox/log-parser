class LogParser
  module FileHelper

    extend ::ActiveSupport::Concern

    included do |base|

      def read_file
        raise ::LogParser::Exceptions::FileNotFound if !File.exist?(full_file_path)

        file = File.new(full_file_path)

        file.each_line do |line|
          store_file_line(line)
        end

        file.close()

        nil
      end

      def store_file_line(line)
        self.current_line_type = nil
        return nil if ignore_line?(line)

        processed_data = process_line(line)
        update_local_storage(processed_data)
      end

      def ignore_line?(line)
        line.match(::LogParser::REQUEST_MASK).nil?
      end

      def process_line(line)
        hash = {}

        parts = line.split(' ')
        parts.each do |line_part|
          key, value = line_part.split('=')
          next if value.nil? || !self.required_keys.include?(key)

          hash.store(key.to_sym, processed_value(key, value))
        end

        hash
      end

      def update_local_storage(data)
        set_current_type(data)
        set_mean_data(data)
        set_median_data(data)
        set_mode_data(data)
      end

      def processed_value(key, value)
        return value if !self.class._processable_keys.include?(key)

        send("process_#{key}".to_sym, value)
      end

      def process_connect(value)
        value.gsub('ms', '').to_i
      end

      def process_service(value)
        value.gsub('ms', '').to_i
      end

      def full_file_path
        File.expand_path(File.join(File.dirname(__FILE__), self.file_path,  self.file_name))
      end

    end

  end
end