class AddedtranslationsinDb < ActiveRecord::Migration
  def self.up
    create_table :translations do |t|
        t.string :locale
        t.string :key
        t.text   :value
        t.text   :interpolations
        t.boolean :is_proc, :default => false
    end
  end

  def self.down
    delete_table :translations
  end
end
