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
        let(:o) { Starter.options('1_test_100b') }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should have empty output dir' do
            expect(@fs).to be_empty
        end

        it 'should process 1_test_100b' do
            Restore.new.process_file(o)
        end

        it 'should get files in output directory' do
            expect(@fs).not_to be_empty
        end

        it 'should have 1 file in dir' do
            expect(@fs.length).to eq(1)
        end

        it 'should be correct' do
            expect(Result.correct?(@fs.first)).to eq(true)
        end

        it 'should be 100 bite length' do
            expect(File.size(@fs.first)).to eq(100)
        end
    end

    context '2_test_111b' do
        let(:o) { Starter.options('2_test_111b') }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should have empty output dir' do
            expect(@fs).to be_empty
        end

        it 'should process 2_test_111b' do
            Restore.new.process_file(o)
        end

        it 'should get files in output directory' do
            expect(@fs).not_to be_empty
        end

        it 'should have 1 file in dir' do
            expect(@fs.length).to eq(1)
        end

        it 'should be correct' do
            expect(Result.correct?(@fs.first)).to eq(true)
        end

        it 'should be 111 bite length' do
            expect(File.size(@fs.first)).to eq(111)
        end
    end

    context '3_test_2x100b' do
        let(:o) { Starter.options('3_test_2x100b') }

        before(:all) { MyDir.clear }
        before(:each) { @fs = MyDir.files }

        it 'should have empty output dir' do
            expect(@fs).to be_empty
        end

        it 'should process 3_test_2x100b' do
            Restore.new.process_file(o)
        end

        it 'should get files in output directory' do
            expect(@fs).not_to be_empty
        end

        it 'should have 2 file in dir' do
            expect(@fs.length).to eq(2)
        end

        it 'should be correct' do
            @fs.each do |fs|
                expect(Result.correct?(fs)).to eq(true)
            end
        end

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
end
