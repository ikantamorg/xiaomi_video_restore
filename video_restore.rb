#!/usr/bin/env ruby
require 'optparse'
# require 'ostruct'
# require 'pp'
require 'pry'


class OptparseExample
  Version = '0.0.1'.freeze

  attr_reader :parser, :options

  class ScriptOptions
    attr_accessor :input, :output, :start, :extention

    def initialize
      self.input = nil
      self.output = './output/'
      self.start = "\x00\x00\x00 ftypavc1"
      self.extention = "mp4"
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
    raise "Missing input file"  if options.input.nil?
  end
end

class Buffer
  FILE_NAME = "export_%05i"

  attr_reader :path, :file
  attr_accessor :started
  @@index = 0

  def initialize(options)
    @empty = true
    @path = "#{ options.output }#{ FILE_NAME % @@index }.#{ options.extention }"
    # p "File path: #{@path}"
    # p

    @file = File.new(@path, 'w+')
  end

  def get_index
    @@index += 1
  end

  def add(data)
    @file.write(data)
    @empty = false
  end

  def close
    unless empty?
      p "Closed file: #{@path}"
      @file.close()
    else
      File.delete(@path)
    end
  end

  def empty?
    @empty
  end

  def started?
    @started
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
  p "Options:"
  p options
  p ''

  unless File.exists? options.input
    p "File '#{options.input}' not found"
    exit
  end
  p "Start process..."
  reader = File.new(options.input, 'rb')

  process_file(options, reader)

  reader.close

  p "End!"
end

def get_count(last, poz)
  poz - last
end

def process_part(options, part, buf)
  last = -1
  len = part.length

  while last < len do
    poz = part.index(options.start, last + 1)
    if poz.nil?
      # p "Poz not finded"
      unless buf.started?
        count = get_count(last, poz)
        buf.add(part.biteslice(last, count))

        buf.add(part)
      end
      last = len
    else

      # p "Find start poz=#{poz}"
      unless buf.started?
        count = get_count(last, poz)
        buf.add(part.biteslice(last, count))
        buf.close
        last += count
        buf = Buffer.new(options)
      else
        buf.started?
        last = poz + 1
      end
    end
  end
end

def process_file(options, reader)
  buf = Buffer.new(options)
  i = 0
  while (part = reader.gets(100))
    p "Process part: #{i}"
    p part
    process_part(options, part, buf)
    i += 1
    exit
  end
  buf.close
end


main
