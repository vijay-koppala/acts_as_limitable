class CreateLimitDefinitions < ActiveRecord::Migration
  def self.up
    create_table :limit_definitions do |t|
      t.string :aspect, :limit => 50, :default => "all"     # what is being limited: email, api
      t.string :role, :limit => 50, :default => "default"   # lite, pro, etc...
      t.string :interval_expression, :limit => 50           # "1.week", "1.day", etc...
      t.integer :interval_seconds                           # number of seconds in interval_expression
      t.integer :allowance                                  # how many calls are allowed during this interval 
      t.timestamps
    end

    add_index :limit_definitions, [:role, :interval_expression]
  end

  def self.down
    drop_table :limit_definitions
  end
end