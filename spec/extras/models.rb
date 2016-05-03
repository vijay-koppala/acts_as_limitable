#  User - will use a Hash to get it's thresholds
#  ---------------------------------------------------------------------
#  name: String
#  role: String
#
class User < ActiveRecord::Base 

  has_many :limited_user_resources 
  has_many :limitable_models
  has_many :method_configured_limited_models

  def init_limiting
    LimitableModel.init_limiting(self)
    MethodConfiguredLimitedModel.init_limiting(self)
  end
end


module TestMethods 
  def self.included(base)
    base.belongs_to :user  
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
  limitable_owner ->(obj){ (User === obj) ? obj : obj.user }   # ->{ Thread.current[:user].role }

  # takes a user_role
  def self.limit_resolver(user)
    case user.role
    when "user" 
      { 1.second => 5, 1.hour => 100, 1.day => 1000}
    when "public_user"
      { 1.second => 1, 1.hour => 25, 1.day => 100 }
    end
  end

  limitable_methods :limited1, :limited2 

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
  limitable_thresholds user: { 1.second => 5, 1.hour => 100, 1.day => 1000},
                       public_user: { 1.second => 1, 1.hour => 25, 1.day => 100 }

  # Specify how the role will be determined at runtime
  limitable_owner ->(obj){ (User === obj) ? obj : obj.user }   # ->{ Thread.current[:user].role }

  # Specify how the role will be determined at runtime
  limitable_role ->(owner){ owner.role }   # ->{ Thread.current[:user].role }


  limitable_methods :limited1, :limited2 
end



