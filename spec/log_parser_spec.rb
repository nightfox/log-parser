require_relative 'spec_helper'
require_relative '../lib/log_parser'

RSpec.describe ::LogParser, '#summarize' do
  specify { expect { LogParser.new(file_name: 'sample-1.log').summarize }.to output("url=GET /api/users/{user_id}/count_pending_messages:  count=3  mean=15.67ms  median=16ms  mode_for_response=18ms, 13ms, 16ms  most_hit_dyno=web.8, web.12, web.11\nurl=GET /api/users/{user_id}/get_messages:  count=0  mean=0ms  median=0ms  mode_for_response=none  most_hit_dyno=none\nurl=GET /api/users/{user_id}/get_friends_progress:  count=0  mean=0ms  median=0ms  mode_for_response=none  most_hit_dyno=none\nurl=GET /api/users/{user_id}/get_friends_score:  count=0  mean=0ms  median=0ms  mode_for_response=none  most_hit_dyno=none\nurl=POST /api/users/{user_id}:  count=0  mean=0ms  median=0ms  mode_for_response=none  most_hit_dyno=none\nurl=GET /api/users/{user_id}:  count=0  mean=0ms  median=0ms  mode_for_response=none  most_hit_dyno=none\n").to_stdout }

  context 'If log file does not exist' do
    it 'should raise File not found exception' do
      expect { LogParser.new(file_name: 'sample-xyz.log').summarize }.to raise_error(::LogParser::Exceptions::FileNotFound)
    end
  end
end

RSpec.describe ::LogParser, '#ignore_line?' do


  context 'if valid masked log line passed' do
    it 'should return false' do
      @line = "2014-01-09T06:15:15.893505+00:00 heroku[router]: at=info method=GET path=/api/users/1686318645/get_friends_progress host=services.pocketplaylab.com fwd=\"1.125.42.139\" dyno=web.3 connect=8ms service=90ms status=200 bytes=7534"
      expect(LogParser.new.ignore_line?(@line)).to eq(false)
    end
  end



  context 'if invalid log line passed' do
    it 'should return true' do
      @line = "2014-01-09T06:16:53.820106+00:00 heroku[router]: at=info method=POST path=/version_api/files host=services.pocketplaylab.com fwd=\"66.87.90.127\" dyno=web.10 connect=1ms service=83ms status=200 bytes=69"
      expect(LogParser.new.ignore_line?(@line)).to eq(true)
    end
  end

end

RSpec.describe ::LogParser, '#process_line' do


  context 'when a log line is pagged' do
    it 'should return a hash with only relavant data' do
      @line = "2014-01-09T06:15:15.893505+00:00 heroku[router]: at=info method=GET path=/api/users/1686318645/get_friends_progress host=services.pocketplaylab.com fwd=\"1.125.42.139\" dyno=web.3 connect=8ms service=90ms status=200 bytes=7534"
      expect(LogParser.new.process_line(@line)).to eq({method: "GET", path: "/api/users/1686318645/get_friends_progress", dyno: "web.3", connect: 8, service: 90})
    end
  end

end

RSpec.describe ::LogParser, '#set_mean_data' do

  context 'when a valid data hash is passed' do
    it 'should update the hash' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_progress
      parsed.set_mean_data({method: "GET", path: "/api/users/1686318645/get_friends_progress", dyno: "web.3", connect: 8, service: 90})
      min_heap = parsed.local_storage[:get_friends_progress][:min_heap]
      max_heap = parsed.local_storage[:get_friends_progress][:max_heap]
      expect(parsed.local_storage[:get_friends_progress]).to eq({count: 1, total_time: 98, min_heap: min_heap, max_heap: max_heap, dyno_frequency_hash: {}, response_frequency_hash: {}, median: 0})
    end
  end

end

RSpec.describe ::LogParser, '#set_current_type' do

  context 'data corresponds to post_user' do
    it 'current_type should be create_user' do
      parsed = LogParser.new
      parsed.set_current_type({method: "POST", path: '/api/users/1686318645', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:create_user)
    end
  end

  context 'data corresponds to show_user' do
    it 'current_type should be show_user' do
      parsed = LogParser.new
      parsed.set_current_type({method: "GET", path: '/api/users/1686318645', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:show_user)
    end
  end

  context 'data corresponds to friends_progress' do
    it 'current_type should be friends_progress' do
      parsed = LogParser.new
      parsed.set_current_type({method: "GET", path: '/api/users/1686318645/get_friends_progress', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:get_friends_progress)
    end
  end

  context 'data corresponds to count_pending_messages' do
    it 'current_type should be count_pending_messages' do
      parsed = LogParser.new
      parsed.set_current_type({method: "GET", path: '/api/users/1686318645/count_pending_messages', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:count_pending_messages)
    end
  end

  context 'data corresponds to get_messages' do
    it 'current_type should be get_messages' do
      parsed = LogParser.new
      parsed.set_current_type({method: "GET", path: '/api/users/1686318645/get_messages', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:get_messages)
    end
  end

  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.set_current_type({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.current_line_type).to eq(:get_friends_score)
    end
  end

end

RSpec.describe ::LogParser, '#set_median_data' do
  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_score
      parsed.local_storage[:get_friends_score][:max_heap].push(100)
      parsed.local_storage[:get_friends_score][:median] = 100
      parsed.set_median_data({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.local_storage[:get_friends_score][:median]).to eq(99.0)
    end
  end

  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_score
      parsed.local_storage[:get_friends_score][:max_heap].push(100)
      parsed.local_storage[:get_friends_score][:min_heap].push(100)
      parsed.local_storage[:get_friends_score][:median] = 100
      parsed.set_median_data({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 90})
      expect(parsed.local_storage[:get_friends_score][:median]).to eq(100)
    end
  end

  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_score
      parsed.local_storage[:get_friends_score][:max_heap].push(88)
      parsed.local_storage[:get_friends_score][:min_heap].push(92)
      parsed.local_storage[:get_friends_score][:median] = 90
      parsed.set_median_data({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 60})
      expect(parsed.local_storage[:get_friends_score][:median]).to eq(88)
    end
  end

  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_score
      parsed.local_storage[:get_friends_score][:min_heap].push(88)
      parsed.local_storage[:get_friends_score][:median] = 88
      parsed.set_median_data({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 100})
      expect(parsed.local_storage[:get_friends_score][:median]).to eq(88)
    end
  end

  context 'data corresponds to get_friends_score' do
    it 'current_type should be get_friends_score' do
      parsed = LogParser.new
      parsed.current_line_type = :get_friends_score
      parsed.local_storage[:get_friends_score][:max_heap].push(88)
      parsed.local_storage[:get_friends_score][:median] = 88
      parsed.set_median_data({method: "GET", path: '/api/users/1686318645/get_friends_score', dyno: "web.3", connect: 8, service: 100})
      expect(parsed.local_storage[:get_friends_score][:median]).to eq(98.0)
    end
  end
end

