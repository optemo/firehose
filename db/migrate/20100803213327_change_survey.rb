class ChangeSurvey < ActiveRecord::Migration
  def self.up
    remove_column :surveys, :suggestions
    add_column :surveys, :firstname, :string
    add_column :surveys, :lastname, :string
    add_column :surveys, :rating, :string
    add_column :surveys, :followup, :boolean
    add_column :surveys, :email, :string
    add_column :surveys, :experience, :text
    add_column :surveys, :improvements, :text
  end 

  def self.down
    add_column :surveys, :suggestions, :text
    remove_column :surveys, :firstname
    remove_column :surveys, :lastname
    remove_column :surveys, :rating
    remove_column :surveys, :followup
    remove_column :surveys, :email
    remove_column :surveys, :experience
    remove_column :surveys, :improvements
  end
end
