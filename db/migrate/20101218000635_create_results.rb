class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.integer :total
      t.integer :errors
      t.integer :warnings

      t.timestamps
    end
  end

  def self.down
    drop_table :results
  end
end
