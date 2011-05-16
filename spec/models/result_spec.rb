require 'spec_helper'

describe Result do
  before(:each) do
    @time = Time.zone.now
    @attr = {:total=>10, :error_count=>3, :warning_count=>nil, :product_type=>'camera_bestbuy', :category=>'---\r-20218', :created_at=>@time, :updated_at=>@time}
    @candidate = {:result_id=>1}
  end

  it "should create 1 restul" do
    Result.create!(@attr)
    Result.count.should be_equal(1)
  end

  it "should create 10 results" do
    Result.create!(@attr)
    1.upto(9) do |i|
      Result.create!(@attr.merge(:created_at=>@time - i.day))
    end
    Result.count.should be_equal(10)
  end

  
  describe "clean up" do
    it "should keep only 3 results" do
      Result.create!(@attr)
      1.upto(9) do |i|
        Result.create!(@attr.merge(:created_at=>@time - i.day))
      end
      Result.cleanupByProductType('camera_bestbuy', 3)
      Result.count.should be_equal(3)
    end

    it "should leave 3 days results even if the created dates are not consistant" do
      Result.create!(@attr)
      1.upto(9) do |i|
        Result.create!(@attr.merge(:created_at=>@time - i*2.day ))
      end
      Result.cleanupByProductType('camera_bestbuy', 3)
      Result.count.should be_equal(3)

    end

    it "should leave 3 days results even if there are more than one results in same day" do
      Result.create!(@attr)
      Result.create!(@attr.merge(:created_at=>@time + 1.hour))
      1.upto(9) do |i|
        Result.create!(@attr.merge(:created_at=>@time - i.day + 1.hour)) if i == 1
        Result.create!(@attr.merge(:created_at=>@time - i.day ))
      end
      Result.cleanupByProductType('camera_bestbuy', 3)
      Result.count.should be_equal(5)

    end

    

    it "should remove candidates related with results" do
      result = Result.new(@attr)
      result.candidates = Array.new
      result.candidates << Candidate.new(@candidate.merge(:result_id=>result.id))
      result.save
      1.upto(9) do |i|
        result = Result.new(@attr.merge(:created_at=>@time - i.day))
        result.candidates << Candidate.new(@candidate.merge(:result_id=>result.id))
        result.save
      end

      Result.cleanupByProductType('camera_bestbuy', 3)
      Candidate.count.should be_equal(3)
    end



  end
  describe "create_from_current" do
    it "should create candidates when a result generated" do
      pending ""
    end
  end
end
