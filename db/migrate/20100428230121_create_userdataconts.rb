class CreateUserdataconts < ActiveRecord::Migration
  def self.up
    create_table :userdataconts do |t|
      t.primary_key :id
      t.integer :search_id
      t.string :name
      t.float :min
      t.float :max

      t.timestamps
    end
  end

  def self.down
    drop_table :userdataconts
  end
end
