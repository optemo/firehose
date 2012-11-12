class ChangeKeywordSearchCountType < ActiveRecord::Migration
  def up
    change_column :keyword_searches, :count, :float
  end

  def down
    change_column :keyword_searches, :count, :integer
  end
end
