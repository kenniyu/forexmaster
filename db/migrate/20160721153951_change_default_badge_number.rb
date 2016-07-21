class ChangeDefaultBadgeNumber < ActiveRecord::Migration
  def change
    change_column :push_tokens, :badge, :integer, :default => 0
  end
end
