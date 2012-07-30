class ChangeEqIdType < ActiveRecord::Migration
  def up
    change_column :equivalences, :eq_id, :string
  end

  def down
    change_column :equivalences, :eq_id, :integer
  end
end
