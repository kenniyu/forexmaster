class CreateTrades < ActiveRecord::Migration
  def change
    create_table :trades do |t|
      t.string :pair
      t.integer :status
      t.integer :size
      t.decimal :mark

      t.timestamps null: false
    end
  end
end
