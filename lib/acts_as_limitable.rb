require "active_record"
require 'active_support/concern'

$LOAD_PATH.unshift(File.dirname(__FILE__))

module ActsAsLimitable

  if defined?(ActiveRecord::Base)
    require "acts_as_limitable/limitable"
  end

end