class AddBadgeToPushToken < ActiveRecord::Migration
  def change
    add_column :push_tokens, :badge, :integer
  end
end
