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

  def self.incr_bucket_val aspect, owner_id, at_time: , duration:, amount: 0
    bucket = "AAL_#{aspect}:#{owner_id}:#{duration}:#{(at_time.to_i / duration).to_i}"
    Rails.logger.debug "ActsAsLimitable: Incrementing #{bucket} with amount[#{amount}]"
    redis_client.pipelined do
      if amount == -1
        redis_client.del bucket 
      end
      @count = redis_client.incrby(bucket, amount)
      redis_client.expire(bucket, duration)
    end
    return @count.value
  end    

  def self.check_limit aspect, owner_id, at_time: , duration:, limit:, amount: 1 
    current_val = incr_bucket_val aspect, owner_id, at_time: at_time, duration: duration, amount: 0
    Rails.logger.debug "ActsAsLimitable: checking for #{amount} available while currently at[#{current_val}]"
    if (current_val + amount) > limit
      Rails.logger.warn "ActsAsLimitable: #{current_val + amount} is greater than #{limit}!!!"
      return false
    end
    true
  end

  def self.incr_bucket_vals aspect, owner_id,at_time: Time.now.utc, limits:, amount: 1
    limits.each do |duration, limit|
      response = incr_bucket_val(aspect,owner_id, at_time: Time.now.utc, duration: duration.to_i, 
          amount: amount)
    end
   end

  # Check multiple buckets
  def self.check_limit_multi aspect, owner_id, at_time: Time.now.utc, amount: 1,
                            limits: [{1.seconds => 10}, {1.minutes => 120}, {1.hour => 240} ]
    error_message = nil
    limits.each do |duration, limit|
      response = check_limit(aspect,owner_id, at_time: Time.now.utc, duration: duration.to_i, 
          limit: limit, amount: amount)
      if response == false
        error_message ||= "You can only make #{limit} calls every #{duration} second(s)"
      end
    end
    if !error_message.nil?
      msg = "ActsAsLimitable: Rate limiting violated: #{error_message}"
      Rails.logger.warn msg
      raise msg
    end
    true
  end



end