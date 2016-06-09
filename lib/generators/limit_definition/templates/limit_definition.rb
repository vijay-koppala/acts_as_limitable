# == Schema Information
#
# Table name: limit_definitions
#
#  id                  :integer          not null, primary key
#  aspect              :string(50)       default("default")
#  role                :string(50)       default("default")
#  interval_expression :string(50)
#  interval_seconds    :integer
#  allowance           :integer
#  created_at          :datetime
#  updated_at          :datetime
#
#########################################################################################
#
#
#               aspect:  What aspect of your system is being rate-limited?  
#                         "Email.send", "API:my_endpoint"
#
#                 role:  What role will this limit belong to?  (think subscription level)
#                         "pro", "lite", "anonymous"
#
#  interval_expression: A user friendly (activesupport) representation of a duration
#                         "1.week", "1.month"
#
#     interval_seconds: The number of seconds that interval_expression evaluates to
#                         
#
#            allowance:  How many calls are allowed during this interval?
#                           100, 500, 1000
#
class LimitDefinition < ActiveRecord::Base
  before_save   :set_interval
  after_commit  :clear_cache
  @@cached ||= {}

  #
  # Performs a fast lookup of the configured limits for a given aspect
  #
  def self.limits_config aspect
    return @@cached[aspect] if @@cached[aspect]
    m = {}
    LimitDefinition.where(aspect: aspect).order("role ASC, interval_seconds ASC").each do |ld|
      role_map = m[ld.role] || {} 
      role_map[ld.interval_seconds] = ld.allowance
      m[ld.role] = role_map
    end
    @@cached[aspect] = m 
    m
  end

  #
  # Takes a limits configuration and builds the corresponding LimitDefinition entries
  #
  #    create_limits("Email.send",   config: { user: { 1.second => 5, 1.hour => 100, 1.day => 1000},
  #                                         public_user: { 1.second => 1, 1.hour => 25, 1.day => 100 }
  #                                         })
  #
  def self.create_limits aspect, config: 
    config.each do |role, limits| 
      limits.each do |interval, allowance|
        LimitDefinition.create(     aspect: aspect, 
                                      role: role, 
                       interval_expression: interval, 
                                 allowance: allowance) 
      end
    end
  end

  #
  # Return the Limit configuration for a particular aspects role
  #
  def self.for_role aspect, role_name
    limits_config(aspect)[role_name]
  end

  private
  def set_interval
    self.interval_seconds = eval(interval_expression).to_i
  end

  def clear_cache
    @@cached[self.aspect.presence || "default"] = nil 
  end

  def self.clear_caches
    @@cached = {}
  end
end
