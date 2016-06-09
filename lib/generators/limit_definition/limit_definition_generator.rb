require 'rails/generators/migration'

class LimitDefinitionGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    @_acts_as_limitable_source_root ||= File.expand_path("../templates", __FILE__)
  end

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_model_file
    template "limit_definition.rb", "app/models/limit_definition.rb"
    migration_template "create_limit_definitions.rb", "db/migrate/create_limit_definitions.rb"
  end
end