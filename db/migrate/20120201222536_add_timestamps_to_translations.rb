class AddTimestampsToTranslations < ActiveRecord::Migration
  def change
    add_column :translations, :created_at, :datetime
    add_column :translations, :updated_at, :datetime
  end
end
