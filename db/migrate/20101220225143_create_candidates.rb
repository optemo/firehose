class CreateCandidates < ActiveRecord::Migration
  def self.up
    create_table :candidates do |t|
      t.integer :scraping_rule_id
      t.integer :result_id
      t.integer :product_id
      t.string :parsed
      t.string :raw

      t.timestamps
    end
    add_index('candidates', 'result_id')
  end

  def self.down
    drop_table :candidates
    remove_index('candidates', 'result_id')
  end
end
