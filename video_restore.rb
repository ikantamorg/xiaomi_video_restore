#!/usr/bin/env ruby
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptparseExample
  Version = '0.0.1'.freeze

  attr_reader :parser, :options

  class ScriptOptions
    attr_accessor :input, :output, :start

    def initialize
      self.output = './output/'
      self.start = 0x000000206674797061766331
    end
  end

  def initialize
    @options = ScriptOptions.new
  end

  def self.parse(args)
    my_parser = new
    my_parser.option_parser.parse!(args)
    my_parser.options
  end

  def option_parser
    @parser ||= OptionParser.new do |parser|
      parser.banner = 'Usage: example.rb [options]'
      parser.separator ''
      parser.separator 'Specific options:'

      parser.on('-i', '--input [FILE]', String, :required,
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
        puts parser
        exit
      end
      check_options
    end
  end

  def check_options
    raise "Missing input file"  if @options.input.nil?
  end
end # class OptparseExample

def main
  begin
    options = OptparseExample.parse(ARGV)
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
    pp e
  rescue Exception => e
    pp e
    exit
  end
  pp options
end

main
