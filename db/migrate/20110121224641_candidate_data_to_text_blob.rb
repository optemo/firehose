class CandidateDataToTextBlob < ActiveRecord::Migration
  def self.up
    change_column(:candidates, :parsed, :text)
    change_column(:candidates, :raw, :text)
  end

  def self.down
    change_column(:candidates, :parsed, :string)
    change_column(:candidates, :raw, :string)
  end
end
