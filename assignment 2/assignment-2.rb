script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'

# custom methods and structures defined in core_ext.rb
require_relative 'functions'

# commandline parsing
options = {}
option_parser = OptionParser.new do |opt|
  opt.banner = "Usage 'ruby #{script} [Arguments]'"
  opt.separator ''
  opt.on('-h', '--help', 'Display help') do
    puts opt
    exit
  end
  opt.separator 'required Arguments:'
  opt.on('-d', '--data [FILE]', 'Path to data .csv') do |path|
    options[:data_path] = path
  end
  opt.on('-o', '--output [FILE]', 'Path to output .xml') do |path|
    options[:output_path] = path
  end
  opt.separator ''
  opt.separator 'optional Arguments:'
  opt.on('-v', '--verbose', 'Write a lot of information') do
    $VERBOSE = true
  end
end

option_parser.parse!

# Check input
if options[:data_path].nil?
  puts "Missing Arguments. See #{script} -h"
  exit(-1)
end

## Check existence of data file
unless File.file? options[:data_path]
  puts "#{options[:data_path]} doesn't exist!"
end

## Check given output (correct: not given at all)
if options[:output_path].nil? ||
  options[:output_path] = File.basename(options[:data_path], '.*') << '_output.xml'
  puts "No output specified. Writing to #{options[:output_path]}"
end

# loading Data
puts '=== Loading Data'
data = []
CSV.read(options[:data_path]).each do |row|
  # Format:
  # [
  #   [[att0, att1, ...],class]
  #   .
  #   .
  #   .
  # ]
  data.append [row[0..-2], row.last]
end
puts '=== Done: Loading Data'

puts '=== ID3'

tree = get_tree(data)

puts '=== DONE: ID3'

puts '=== Creating XML'
puts "Writing to: #{options[:output_path]}"
File.open(options[:output_path], 'w+') do |f|
  write_tree(f, tree)
end

puts '=== DONE: Creating XML'
