class CreateDelinquents < ActiveRecord::Migration
  def self.up
    create_table :delinquents do |t|
      t.integer :scraping_rule_id
      t.integer :result_id
      t.integer :product_id
      t.string :parsed
      t.string :raw

      t.timestamps
    end
  end

  def self.down
    drop_table :delinquents
  end
end
