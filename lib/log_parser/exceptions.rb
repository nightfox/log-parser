class LogParser
  module Exceptions
    class FileNotFound < ::Exception

      def initialize(message=nil, object=nil)
        message ||= 'Cannot find the specified log file'
        super(message)
        @object = object
      end
    end
  end
end