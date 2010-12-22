class CreateUserdatabins < ActiveRecord::Migration
  def self.up
    create_table :userdatabins do |t|
      t.primary_key :id
      t.integer :search_id
      t.string :name
      t.boolean :value

      t.timestamps
    end
  end

  def self.down
    drop_table :userdatabins
  end
end
