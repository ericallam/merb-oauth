class InitialSchema < ActiveRecord::Migration

  def self.up
    create_table "client_applications", :force => true do |t|
      t.string   "name"
      t.string   "url"
      t.string   "support_url"
      t.string   "callback_url"
      t.string   "key",          :limit => 50
      t.string   "secret",       :limit => 50
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

    create_table "tokens", :force => true do |t|
      t.string   "type",                  :limit => 20
      t.integer  "client_application_id", :limit => 11
      t.string   "token",                 :limit => 50
      t.string   "secret",                :limit => 50
      t.datetime "authorized_at"
      t.datetime "invalidated_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "tokens", ["token"], :name => "index_tokens_on_token", :unique => true
  end
  
  def self.down
    
  end
  
end
