require 'spec_helper'

describe "Check start options" do
  let(:o) { Starter.options("test") }
  it "should initialize options" do
    expect(o).not_to be_nil
  end

  it "should have input file" do
    expect(o).to have_attributes(input: a_string_matching(/test/))
  end

  it "should have part_size eq 50" do
    expect(o).to have_attributes(part_size: 50)
  end
end

describe "Runner" do
  let(:o) { Starter.options("1_test_100b") }

  it "should sucessfully run process" do
    Restore.new.process_file(o)
  end
end

describe "Test data" do

  describe  "1_test_100b" do
    before(:all) do
      MyDir.clear
    end

    before(:each) do
      @fs = MyDir.files
    end

    let(:o) {Starter.options("1_test_100b")}

    it "should have empty output dir" do
      expect(@fs).to be_empty
    end

    it "should process 1_test_100b" do
      Restore.new.process_file(o)
    end

    it "should get files in output directory" do
      expect(@fs).not_to be_empty
    end

    it "should have 1 file in dir" do
      expect(@fs.length).to eq(1)
    end

    it "should be correct" do
      expect(Result.correct?(@fs.first)).to eq(true)
    end

    it "should be 100 bite length" do
      expect(File.size(@fs.first)).to eq(100)
    end
  end
end
