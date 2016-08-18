#  User - will use a Hash to get it's thresholds
#  ---------------------------------------------------------------------
#  name: String
#  role: String
#
class User < ActiveRecord::Base 

  has_many :limited_user_resources 
  has_many :limitable_models
  has_many :method_configured_limited_models

end

load "lib/generators/limit_definition/templates/limit_definition.rb"

module TestMethods 
  module ClassMethods
    def static_method
      puts "static_method"
    end
  end

  def self.included(base)
    base.belongs_to :user  
    base.extend ClassMethods                                                                                                                                                  
  end

  def limited1;puts "limited1";end
  def limited2;puts "limited2";end
  def not_limited;print ".";end
end


#  MethodConfiguredLimitedModel - will use a method to determine thresholds
#  --------------------------------------------------------------------------
#  user_id: Integer
#
class MethodConfiguredLimitedModel < ActiveRecord::Base 
  include ActsAsLimitable::Limitable 
  include TestMethods

  scope :limitable_scope, ->(u){select("created_at as at_time, 1 as cnt").where("user_id = ?", u.id)}

  limitable_thresholds :limit_resolver

  # Specify how the role will be determined at runtime
  limitable_owner do |obj, args| 
    (User === obj) ? obj : (obj.user rescue Thread.current[:user])
  end   # ->{ Thread.current[:user].role }

  # takes a user
  def self.limit_resolver(aspect, user)
    case (user.role rescue 'public_user')
    when "user" 
      { 1.second => 5, 1.hour => 100, 1.day => 1000}
    when "public_user"
      { 1.second => 1, 1.hour => 25, 1.day => 100 }
    end
  end

  limitable_methods :limited1, :limited2, :static_method

end


#  LimitableModel - will use a Hash to get it's thresholds
#  ---------------------------------------------------------------------
#  user_id: Integer
#
class LimitableModel < ActiveRecord::Base 
  include ActsAsLimitable::Limitable 
  include TestMethods

  scope :limitable_scope, ->(u){select("created_at as at_time, 1 as cnt").where("user_id = ?", u.id)}

  # Specify per-role thresholds that will be respected by limiting logic
  #      role => { duration1 => quantity1, duration2 => quantity2 } 
  #
  limitable_thresholds default: {      user: { 1.second => 5, 1.hour => 100, 1.day => 1000},
                                public_user: { 1.second => 1, 1.hour => 25, 1.day => 100 },
                                system: {}},
                       "extremely_restricted" =>  {user: { 1.second => 1, 1.hour => 1, 1.day => 1},
                                public_user: { 1.second => 1, 1.hour => 1, 1.day => 1 },
                                system: {}
                       }

  # Specify how the role will be determined at runtime
  limitable_owner do |obj, args| 
    (User === obj) ? obj : (obj.user rescue Thread.current[:user])
  end   # ->{ Thread.current[:user].role }

  # Specify how the role will be determined at runtime
  limitable_role do |owner|
    owner.role rescue :public_user
  end  # ->{ Thread.current[:user].role }

  def limited_by_args_val params = {}
    puts 'This will be marked up to always require 10,000 units in order to run'
  end

  def extremely_restricted
    puts "extremely_restricted"
  end

  limitable_methods :limited1, :limited2, :static_method

  limitable_method :limited_by_args_val, aspect: "other" do |obj, args| 
    args[:val]
  end

  limitable_method :extremely_restricted, aspect: "extremely_restricted"

end



