require "active_record"
require 'active_support/concern'
require 'redis'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsLimitable

  if defined?(ActiveRecord::Base)
    require "acts_as_limitable/limitable"
  end

  # Clients can set redis_host and redis_port 
  mattr_accessor :redis_host
  @@redis_host ||= "localhost"

  mattr_accessor :redis_port
  @@redis_port ||= 6379

  mattr_accessor :redis_namespace
  @@redis_namespace ||= ""

  mattr_accessor :redis_client

  # Call with force=true to guarantee a new connection to redis is returned
  def self.redis_client(force=false)
    if @@redis_client.blank? || force
      @@redis_client ||= Redis.new(host:redis_host, port:redis_port)
    end
    @@redis_client
  end

  def self.incr_bucket_val aspect, owner_id, at_time: , duration:, amount: 0
    # Our keys may be long, but not troublingly so...
    # http://adamnengland.com/2012/11/15/redis-performance-does-key-length-matter/
    bucket = "#{redis_namespace}_AAL_#{aspect}:#{owner_id}:#{duration}"
    bucket = "#{bucket}:#{(at_time.to_i / duration.to_i)}" if duration.to_i > 0

    Rails.logger.debug "ActsAsLimitable: Incrementing #{bucket} with amount[#{amount}]"
    redis_client.pipelined do
      if amount == -1
        redis_client.del bucket 
      end
      @count = redis_client.incrby(bucket, amount)
      redis_client.expire(bucket, duration.to_i)
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
      response = incr_bucket_val(aspect,owner_id, at_time: Time.now.utc, duration: duration, 
          amount: amount)
    end
   end

  # Check multiple buckets
  def self.check_limit_multi aspect, owner_id, at_time: Time.now.utc, amount: 1,
                            limits: [{1.seconds => 10}, {1.minutes => 120}, {1.hour => 240} ]
    limit_error = catch(:limit_error) do
       limits.each do |duration, limit|
        response = check_limit(aspect,owner_id, at_time: Time.now.utc, duration: duration, 
            limit: limit, amount: amount)

        throw :limit_error, {
          limit: limit, duration: duration, message: "You can only make #{limit} calls every #{duration.to_i} second(s)"
        } if response == false
      end
      nil
    end

    if limit_error.present?
      msg = "ActsAsLimitable: Rate limiting violated: #{limit_error[:message]}"
      Rails.logger.warn msg
      raise Limitable::LimitExceededError.new(msg, limit_error[:limit], limit_error[:duration].to_i)
    end

    true
  end
end