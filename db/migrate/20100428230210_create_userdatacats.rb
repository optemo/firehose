class CreateUserdatacats < ActiveRecord::Migration
  def self.up
    create_table :userdatacats do |t|
      t.primary_key :id
      t.integer :search_id
      t.string :name
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :userdatacats
  end
end
