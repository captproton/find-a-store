# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "assets", :force => true do |t|
    t.string   "filename"
    t.integer  "width",           :limit => 11
    t.integer  "height",          :limit => 11
    t.string   "content_type"
    t.integer  "size",            :limit => 11
    t.string   "attachable_type"
    t.integer  "attachable_id",   :limit => 11
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "thumbnail"
    t.integer  "parent_id",       :limit => 11
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_login_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.integer  "visits_count",              :limit => 11, :default => 0
    t.string   "time_zone",                               :default => "Etc/UTC"
    t.string   "permalink"
  end

end
