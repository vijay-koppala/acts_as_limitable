ActiveRecord::Schema.define :version => 1 do

  create_table "limit_definitions", force: :cascade do |t|
      t.string :aspect, :limit => 50, :default => "default"     # what is being limited: email, api
    t.string   "role",                limit: 50, default: "default"
    t.string   "interval_expression", limit: 50
    t.integer  "interval_seconds"
    t.integer  "allowance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "limit_definitions", ["aspect", "role"], name: "index_limit_definitions_on_aspect_and_role"

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