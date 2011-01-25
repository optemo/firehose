class NonuniqueCount < ActiveRecord::Migration
  def self.up
    add_column :results, :nonuniq, :integer
  end

  def self.down
  end
end
