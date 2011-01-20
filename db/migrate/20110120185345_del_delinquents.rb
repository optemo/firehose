class DelDelinquents < ActiveRecord::Migration
  def self.up
    drop_table :delinquents
  end

  def self.down
  end
end
