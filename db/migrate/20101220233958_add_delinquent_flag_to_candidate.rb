class AddDelinquentFlagToCandidate < ActiveRecord::Migration
  def self.up
    add_column :candidates, :delinquent, :boolean, :default => 0
  end

  def self.down
    remove_column :candidates, :delinquent
  end
end
