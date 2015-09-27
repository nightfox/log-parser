require 'active_support/concern'
require 'active_support/hash_with_indifferent_access'
require 'algorithms'
require 'ruby-prof'

require_relative 'log_parser/regex_helper'
require_relative 'log_parser/file_helper'
require_relative 'log_parser/mean_helper'
require_relative 'log_parser/median_helper'
require_relative 'log_parser/mode_helper'
require_relative 'log_parser/exceptions'

class LogParser

  class << self
    attr_accessor :_processable_keys
  end

  REQUEST_MASK = /((method=GET path=\/api\/users\/[0-9]*(\/)?(count_pending_messages|get_messages|get_friends_progress|get_friends_score)?)|(method=POST path=\/api\/users\/[0-9]*)) /

  include ::LogParser::FileHelper
  include ::LogParser::RegexHelper
  include ::LogParser::MeanHelper
  include ::LogParser::MedianHelper
  include ::LogParser::ModeHelper

  attr_accessor :file_name, :file_path, :parsed_data, :request_types, :local_storage, :required_keys, :current_line_type

  def self.processable_keys(*keys)
    self._processable_keys ||= []
    self._processable_keys += keys
  end

  processable_keys 'connect', 'service'

  def initialize(options={})
    self.file_name = options[:file_name] || 'sample.log'
    self.file_path = options[:file_path] || '/../../log/'
    initialize_memory_variables
  end

  def summarize
    read_file
    print_analysis
  end

  def print_analysis
    self.local_storage.each do |key, data|
      output_line = []
      output_line.push("url=#{url[key]}:", "count=#{data[:count]}", print_mean(data[:total_time], data[:count]), print_median(data[:median]), print_frequency_mode(key), print_dyno_mode(key))

      puts output_line.join('  ')
    end
  end

  def initialize_memory_variables
    self.parsed_data = []
    self.request_types = [:count_pending_messages, :get_messages, :get_friends_progress, :get_friends_score, :create_user, :show_user]
    self.local_storage = {}
    self.required_keys = ['method', 'path', 'dyno', 'connect', 'service']

    create_local_storage_for_types
  end

  def create_local_storage_for_types
    self.local_storage = {}
    self.request_types.each do |type|
      max_heap = ::Containers::MaxHeap.new
      min_heap = ::Containers::MinHeap.new
      self.local_storage.store(type, {count: 0, total_time: 0, min_heap: min_heap, max_heap: max_heap, dyno_frequency_hash: {}, response_frequency_hash: {}, median: 0})
    end

    nil
  end

  def url
    {
      count_pending_messages: 'GET /api/users/{user_id}/count_pending_messages',
      get_messages: 'GET /api/users/{user_id}/get_messages',
      get_friends_progress: 'GET /api/users/{user_id}/get_friends_progress',
      get_friends_score: 'GET /api/users/{user_id}/get_friends_score',
      create_user: 'POST /api/users/{user_id}',
      show_user: 'GET /api/users/{user_id}'
    }
  end

end
