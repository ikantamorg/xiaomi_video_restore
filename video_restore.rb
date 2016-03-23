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
      self.input = 'image.img'
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

      parser.on('-i', '--input [FILE]',
                'Input file',
                'Disc image by DD') do |e|
        options.input = e || options.input
      end
      parser.separator ''

      parser.on('-o', '--output [DIRECTORY]',
                'Output directory',
                'Directory to store finded files',
                'Default: "./output/"') do |e|
        options.output = e || options.output
      end
      parser.separator ''

      parser.on('-s', '--start [HEX CHARACTERS]',
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
    end
  end
end # class OptparseExample

pp ARGV
options = OptparseExample.parse(ARGV)
pp options

# User = Struct.new(:id, :name)
#
# def find_user id
#   not_found = ->{ raise "No User Found for id #{id}" }
#   [ User.new(1, "Sam"),
#     User.new(2, "Gandalf") ].find(not_found) do |u|
#     u.id == id
#   end
# end
#
# op = OptionParser.new
# op.accept(User) do |user_id|
#   find_user user_id.to_i
# end
#
# op.on("--user ID", User) do |user|
#   puts user
# end
#
# op.parse!
