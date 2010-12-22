class CreateSurveys < ActiveRecord::Migration
  def self.up
    create_table :surveys do |t|

      t.timestamps
      t.integer :session_id
      # t.text :answers
      Survey::TotalQuestions.times do |ques|
        t.string ("Question"+(ques+1).to_s)
      end
      t.text :suggestions
    end
  end

  def self.down
    drop_table :surveys
  end
end
