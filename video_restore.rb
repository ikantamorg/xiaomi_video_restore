#!/usr/bin/env ruby


require 'optparse'
require 'pry'
require 'action_view'


PART_SIZE = 50

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
      p "Created file: #{@path} #{ActionView::Base.new.number_to_human_size(File.size(@path))}"
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
    p "File '#{options.input}' not found"
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

  itStartPart = -> (_part) {_part == options.start[0.._part.length]}

  tail = ""
  while now < len
    poz = part.index(options.start[0], now)
    unless poz.nil?
      founded_part = part.byteslice(poz)
      if itStartPart[founded_part]
        tail = founded_part
        break
      end
    end
    now += 1
  end

  tail
end

def process_part(options, part, buf, tail, after_limit=false)
  last = -1
  part = tail + part
  tail = ""
  len = part.length
  max = -> (a, b) { a >= b ? a : b }
  get_count = -> (a, b) { b - a}

  while last < len
    poz = part.index(options.start, last + 1)
    if poz.nil?
      tail = getTail(options, part)
      part = part.chomp(tail)
      if buf.started?
        last = max[last, 0]
        count = get_count[last, len + 1]
        added_part = part.byteslice(last, count)
        buf.add(added_part)
      end

      break
    else
      if buf.started?
        count = get_count[last, poz]
        tmp = part.byteslice(last + 1, count)
        buf.add(tmp)
        buf.close
        last += count
        buf = Buffer.new(options)
      else
        buf.start = poz
        last = poz
      end

      return true if after_limit
    end
  end
 return false
end

def read_part(options, offset)
  IO.binread(options.input, PART_SIZE, offset)
end

def process_file(options, start_offset=0, end_offset=nil)
  offset = start_offset
  end_offset ||= File.size(options.input)

  buf = Buffer.new(options)
  tail = ""

  while true
    part = read_part(options, offset)
    break if part.nil?

    if process_part(options, part, buf, tail, offset >= end_offset)
      break
    end
    offset += PART_SIZE
  end
  buf.close
end

main
