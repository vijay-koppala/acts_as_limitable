# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160609175819) do

  create_table "limit_definitions", force: :cascade do |t|
    t.string   "aspect",              limit: 50, default: "default"
    t.string   "role",                limit: 50, default: "default"
    t.string   "interval_expression", limit: 50
    t.integer  "interval_seconds"
    t.integer  "allowance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "limit_definitions", ["role", "interval_expression"], name: "index_limit_definitions_on_role_and_interval_expression"

end
