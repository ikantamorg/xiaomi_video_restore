require 'optparse'
require 'bcrypt'

class OptparseExample
    Version = '0.0.1'.freeze

    attr_reader :parser, :options

    class ScriptOptions
        attr_accessor :input, :output, :start, :extention, :part_size, :threads

        def initialize
            self.input = nil
            self.output = './output/'
            self.start = "\x00\x00\x00 ftypavc1"
            self.extention = 'mp4'
            self.part_size = 50 # bites
            self.threads = 1
        end
    end

    def initialize
        @options = ScriptOptions.new
    end

    def self.parse(args)
        my_parser = new
        my_parser.option_parser.parse!(args)
        my_parser.check_options
        my_parser.options
    end

    def option_parser
        @parser ||= OptionParser.new do |parser|
            parser.banner = 'Usage: example.rb [options]'
            parser.separator ''
            parser.separator 'Specific options:'

            parser.on('-i', '--input [FILE]', String,
                      'Input file (REQUIRED)',
                      'Disc image by DD') do |e|
                options.input = e
            end
            parser.separator ''

            parser.on('-o', '--output [DIRECTORY]', String,
                      'Output directory',
                      'Directory to store finded files',
                      'Default: "./output/"') do |e|
                options.output = e || options.output
            end
            parser.separator ''

            parser.on('-s', '--start [HEX CHARACTERS]', String,
                      'Characters from which files starts',
                      'Default: "0x000000206674797061766331"') do |e|
                options.start = e.hex || options.start
            end

            parser.on('-p', '--part_size [INTEGER]', Integer,
                      'Part size in bites',
                      'Default: 50') do |e|
                options.part_size = e || options.part_size
            end

            parser.on('-t', '--threads [INTEGER]', Integer,
                      'Count threads',
                      'Default: 1') do |e|
                options.threads = e || options.threads
            end

            parser.separator ''
            parser.separator 'Common options:'

            parser.on_tail('-h', '--help', 'Show this message') do
                p parser
                exit
            end
        end
    end

    def check_options
        fail 'Missing input file' if options.input.nil?
    end
end

class Buffer
    FILE_NAME = 'export_%05i'.freeze

    attr_reader :path, :file, :length
    attr_writer :start
    @@index = -1
    @@thread = 0

    def initialize(options, thread=nil)
        @@thread = thread || @@thread
        @path = "#{options.output}#{@@thread}_#{FILE_NAME % get_index}.#{options.extention}"
        fd = IO.sysopen(@path, 'wb')
        @file = IO.new(fd, 'wb')
        @empty = true
        @length = 0
    end

    def get_index
        @@index += 1
    end

    def add(data)
        @file.write(data)
        @empty = false
        @length += data.length
    end

    def close
        unless empty?
            @file.close
        else
            File.delete(@path)
        end
    end

    def empty?
        @empty
    end

    def started?
        !@start.nil?
    end
end

def waste
  10.times { BCrypt::Password.create('secret') }
end

class Restore
    def self.start
        new.main
    end

    def main
        begin
            options = OptparseExample.parse(ARGV)
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
            p e
        rescue Exception => e
            p e
            exit
        end

        unless File.exist? options.input
            exit
        end

        p 'Start process...'

        process_file(options)

        p 'End!'
    end

    def getTail(options, part)
        start_length = options.start.length
        len = part.length
        now = len - start_length

        itStartPart = -> (_part) { _part == options.start[0..._part.length] }

        tail = ''
        while now < len
            poz = part.index(options.start[0], now)
            unless poz.nil?
                founded_part = part[poz, part.length - poz]
                if itStartPart[founded_part]
                    tail = founded_part
                    break
                end
            end
            now += 1
        end

        tail
    end

    def chomp_tail(part, tail)
        part = part[0, part.length - tail.length]
    end

    def process_part(options, part, buf, tail, after_limit = false)
        last = -1
        part = tail + part
        tail = ''
        len = part.length
        max = -> (a, b) { a >= b ? a : b }
        get_count = -> (a, b) { b - a }

        while last < len
            poz = part.index(options.start, last + 1)
            if poz.nil?
                tail = getTail(options, part)
                part = chomp_tail(part, tail)
                if buf.started?
                    last = max[last, 0]
                    count = get_count[last, len + 1]
                    added_part = part[last, count]
                    buf.add(added_part)
                end

                break
            else
                if buf.started?
                    last = max[last, 0]
                    count = get_count[last, poz]
                    if count > 0
                        tmp = part[last, count]
                        buf.add(tmp)
                    end
                    buf.close
                    last += count
                    buf = Buffer.new(options)
                    buf.start = poz
                else
                    buf.start = poz
                    last = poz
                end

                return [buf, true, tail] if after_limit
            end
        end

        [buf, false, tail]
    end

    def read_part(options, offset)
        IO.binread(options.input, options.part_size, offset)
    end

    def process_file(options)
      p "Threads: #{options.threads}"

      max_offset = File.size(options.input)
      part_size = (max_offset / options.threads).ceil
      last = -1
      forks = []
      options.threads.times do |i|
        start = last += 1
        end_part = [last += (part_size - 1), max_offset].min
        # p "Start: #{start}"
        # p "End: #{end_part}"

        l = -> (_start, _end) { process_thread(options, i, _start, _end) }
        forks << fork { l[start, end_part] }
      end

      p Process.waitall

    end

    def process_thread(options, thread=0, start_offset=0, end_offset=nil)
        p "","Start process. thread: #{thread} start_offset: #{start_offset} end_offset: #{end_offset}"
        offset = start_offset
        end_offset ||= File.size(options.input)

        buf = Buffer.new(options, thread)
        tail = ''
        loop do
            # a = Time.now
            part = read_part(options, offset)
            break if part.nil?

            buf, need_break, tail = process_part(options, part, buf, tail, offset >= end_offset)
            break if need_break

            offset += options.part_size
            # p Time.now - a
            waste
            # p Time.now - a
        end
        buf.close
    end
end

Restore.start if __FILE__ == $PROGRAM_NAME
