$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'acts_as_limitable'
require 'logger'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__),'debug.log'))
ActiveRecord::Base.logger.level = Logger::INFO


#load(File.dirname(__FILE__) + '/extra/schema.rb')
#load(File.dirname(__FILE__) + '/extra/models.rb')

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