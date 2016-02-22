ActiveRecord::Schema.define :version => 1 do

  create_table :limitable_models, force: true do |t| 
    t.column :name, :string 
    t.column :role, :string
  end

end