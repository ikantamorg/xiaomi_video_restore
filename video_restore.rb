#!/usr/bin/env ruby
require 'optparse'
# require 'ostruct'
# require 'pp'
require 'pry'

PART_SIZE = 1024

class OptparseExample
  Version = '0.0.1'.freeze

  attr_reader :parser, :options

  class ScriptOptions
    attr_accessor :input, :output, :start, :extention

    def initialize
      self.input = nil
      self.output = './output/'
      self.start = "\x00\x00\x00 ftypavc1"
      self.extention = 'mp4'
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
  @@index = 0

  def initialize(options)
    @empty = true
    @path = "#{options.output}#{FILE_NAME % @@index}.#{options.extention}"
    # p "File path: #{@path}"
    # p
    @file = IO.new(IO.sysopen(@path, "w"), 'w')
    @length = 0

  end

  def get_index
    @@index += 1
  end

  def add(data)
    @empty = false
    @file.write(data)
    @length += data.length
  end

  def close
    unless empty?
      p "Closed file: #{@path}"
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

class Reader
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
  p 'Options:'
  p options
  p ''

  unless File.exist? options.input
    p "File '#{options.input}' not found"
    exit
  end
  p 'Start process...'
  # reader = File.new(options.input, 'rb')
  # begin
    process_file(options)
  # rescue SystemExit, Interrupt
  #   "SystemExit, Interrupt"
  # rescue Exception => e
  #   "Bye"
  # end

  # reader.close

  p 'End!'
end

def get_count(last, poz)
  poz - last
end

def process_part(options, part, buf)
  last = -1
  len = part.length

  while last < len
    poz = part.index(options.start, last + 1)
    if poz.nil?
      # p "Poz not finded. Started? #{buf.started?}"
      if buf.started?
        last = last == -1 ? 0 : last
        count = get_count(last, len + 1)
        added_part = part.byteslice(last, count)
        # p "Added last part. From=#{last} count=#{added_part.length}"
        buf.add(added_part)
      end

      break
    else

      # p "Find start poz=#{poz} Empty? = #{buf.empty?}"
      if buf.started?
        count = get_count(last, poz)
        # p "Last: #{last}, poz: #{poz}, count: #{count}"
        tmp = part.byteslice(last + 1, count)
        # p tmp
        buf.add(tmp)
        buf.close
        # p "File closed!"
        last += count
        buf = Buffer.new(options)
      else
        # p "Start from poz=#{poz}"
        buf.start = poz
        last = poz
      end
    end
  end
 # p "---- End part. length: #{buf.length}"

end

def read_part(options, offset)
  IO.binread(options.input, PART_SIZE, offset)
end

def process_file(options, start_offset=0, end_offset=nil)
  offset = start_offset
  end_offset ||= File.size(options.input)

  buf = Buffer.new(options)
  i = 0

  while (offset < end_offset)
    # p "Process part: #{i}, offset: #{offset}"
    part = read_part(options, offset)
    # p part

    process_part(options, part, buf)
    offset += PART_SIZE
    i += 1
    # exit if offset > 3000
  end
  buf.close
end

main
