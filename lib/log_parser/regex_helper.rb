class LogParser
  module RegexHelper

    extend ::ActiveSupport::Concern

    attr_accessor

    included do |base|

      def set_current_type(data)
        if data[:method] == 'GET'
          path = data[:path].match(/\/api\/users\/[0-9]*[\/]?(count_pending_messages|get_messages|get_friends_progress|get_friends_score)?/)
          if !path[1].nil?
            self.current_line_type = path[1].to_sym
          else
            self.current_line_type = :show_user
          end
        elsif data[:method] == 'POST'
          self.current_line_type = :create_user
        end
      end

    end
  end
end
