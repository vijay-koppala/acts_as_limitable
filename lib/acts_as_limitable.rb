require "active_record"
require 'active_support/concern'
require 'redis'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsLimitable

  if defined?(ActiveRecord::Base)
    require "acts_as_limitable/limitable"
  end

  mattr_accessor :redis_client
  @@redis_client ||= Redis.new

  def self.check_limit identifiers, duration=3600, limit=240
    bucket = "#{identifiers}:#{duration}:#{(Time.now.to_i / duration).to_i}"
    puts "Rate increment for bucket[#{bucket}] - checking (#{duration},#{limit})"
    redis_client.pipelined do
      @count = redis_client.incr(bucket)
      redis_client.expire(bucket, duration)
    end
    if @count.value > limit
      puts "#{@count.value} is greater than #{limit}!!!"
      return false
    end
    true
  end

  # Check multiple buckets
  def self.check_limit_multi identifiers, limits=[{1.seconds => 10}, {1.minutes => 120}, {1.hour => 240} ]
    error_message = nil
    limits.each do |duration, limit|
      response = check_limit(identifiers, duration.to_i, limit)
      if response == false
        error_message ||= "You can only make #{limit} calls every #{duration}"
      end
    end
    if !error_message.nil?
      msg = "Rate limiting violated: #{error_message}"
      puts msg
      raise msg
    end
  end

end