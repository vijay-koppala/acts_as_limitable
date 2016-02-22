class LimitableModel < ActiveRecord::Base 
  include ActsAsLimitable::Limitable 

  # Specify per-role thresholds that will be respected by limiting logic
  #      role => { duration1 => quantity1, duration2 => quantity2 } 
  #
  limitable_thresholds user: { 1.second => 5, 1.hour => 100, 1.day => 1000},
                       public_user: { 1.second => 1, 1.hour => 25, 1.day => 100 }

  # Specify how the role will be determined at runtime
  limitable_role ->(obj){ obj.role }   # ->{ Thread.current[:user].role }

  def limited1
    print "." 
  end

  def limited2
    print "." 
  end

  def not_limited
    print "." 
  end

  limitable_methods :limited1, :limited2 

end