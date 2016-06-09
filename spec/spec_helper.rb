$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'acts_as_limitable'
require 'logger'
require 'byebug'
require 'rails/all'
require 'rspec/rails'

Rails.logger = Logger.new(STDOUT)

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__),'debug.log'))
ActiveRecord::Base.logger.level = Logger::INFO

load(File.dirname(__FILE__) + '/extras/schema.rb')
load(File.dirname(__FILE__) + '/extras/models.rb')

RSpec.configure do |config|
  config.before(:each) do  
    LimitDefinition.delete_all
  end
end


unless [].respond_to?(:freq)
  class Array
    def freq
      k=Hash.new(0)
      each {|e| k[e]+=1}
      k
    end
  end
end

def clean_database!
  # models = [ActsAsTaggable::Tag, ActsAsTaggable::Extra::Tagging, TaggableModel, OtherTaggableModel, InheritingTaggableModel,
  #           AlteredInheritingTaggableModel, TaggableUser, UntaggableModel]
  # models.each do |model|
  #   ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  # end
end