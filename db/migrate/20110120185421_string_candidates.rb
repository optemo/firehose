class StringCandidates < ActiveRecord::Migration
  def self.up
    change_column :candidates, :product_id, :string
  end

  def self.down
    change_column :candidates, :product_id, :integer
  end
end
