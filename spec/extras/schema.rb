ActiveRecord::Schema.define :version => 1 do

  create_table :users, force: true do |t| 
    t.column :name, :string 
    t.column :role, :string
  end

  create_table :limitable_models, force: true do |t| 
    t.column :user_id, :integer
    t.timestamps
  end

  create_table :method_configured_limited_models, force: true do |t| 
    t.column :user_id, :integer
    t.timestamps
  end

end