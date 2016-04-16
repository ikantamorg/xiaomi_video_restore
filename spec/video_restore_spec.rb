require 'spec_helper'

describe 'Check start options' do
    let(:o) { Starter.options('test') }
    it 'should initialize options' do
        expect(o).not_to be_nil
    end

    it 'should have input file' do
        expect(o).to have_attributes(input: a_string_matching(/test/))
    end

    it 'should have part_size eq 50' do
        expect(o).to have_attributes(part_size: 50)
    end
end

describe 'Runner' do
    let(:o) { Starter.options('1_test_100b') }

    it 'should sucessfully run process' do
        Restore.new.process_file(o)
    end
end

describe 'Test data' do
    shared_examples 'process' do |filename, count|
        let(:o) { Starter.options(filename) }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should have empty output dir' do
            expect(@fs).to be_empty
        end

        it 'should process input file' do
            Restore.new.process_file(o)
        end

        it 'should have some files in output directory' do
            expect(@fs).not_to be_empty
        end

        it 'should contain only correct files' do
            @fs.each do |fs|
                expect(Result.correct?(fs)).to eq(true)
            end
        end

        it "should have #{count} file in dir" do
            expect(@fs.length).to eq(count)
        end
    end

    describe '1_test_100b' do
        include_examples 'process', '1_test_100b', 1

        it 'should be 100 bite length' do
            expect(File.size(@fs.first)).to eq(100)
        end
    end

    context '2_test_111b' do
        include_examples 'process', '2_test_111b', 1

        it 'should be 111 bite length' do
            expect(File.size(@fs.first)).to eq(111)
        end
    end

    context '3_test_2x100b' do
        include_examples 'process', '3_test_2x100b', 2

        it 'should be 100 bite length each' do
            @fs.each do |fs|
                expect(File.size(fs)).to eq(100)
            end
        end
    end

    context '4_test_70b_80b' do
        include_examples 'process', '4_test_70b_80b', 2

        it 'should have first file 70 bite length' do
            expect(File.size(@fs.first)).to eq(70)
        end

        it 'should have last file 80 bite length' do
            expect(File.size(@fs.last)).to eq(80)
        end
    end

    context '5_test_273b' do
        include_examples 'process', '5_test_273b', 1

        it 'should have first file 273 bite length' do
            expect(File.size(@fs.first)).to eq(273)
        end
    end

    context '6_test_ori' do
        let(:o) { Starter.options('6_test_ori') }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should process input file' do
            Restore.new.process_file(o)
        end

        it 'should have 1 file in dir' do
            expect(@fs.length).to eq(1)
        end

        it 'should have file 1443021 bite length' do
            expect(File.size(@fs.first)).to eq(1_443_021)
        end
    end

    context '7_test_with_r' do
        let(:o) { Starter.options('7_test_with_r') }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should process input file' do
            Restore.new.process_file(o)
        end

        it 'should have 1 file in dir' do
            expect(@fs.length).to eq(1)
        end

        it 'should have file 100 bite length' do
            expect(File.size(@fs.first)).to eq(100)
        end
    end
end
