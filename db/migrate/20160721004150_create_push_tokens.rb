class CreatePushTokens < ActiveRecord::Migration
  def change
    create_table :push_tokens do |t|
      t.string :token

      t.timestamps null: false
    end
  end
end
