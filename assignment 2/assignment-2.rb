script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'
require 'builder/xmlmarkup'

# custom methods and structures defined in core_ext.rb
require_relative 'new_in'

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

## Check given output (correct extension and not given at all)
if options[:output_path].nil?
  options[:output_path] = File.basename(options[:data_path], '.*') << '_output.xml'
  puts "No output specified. Writing to #{options[:output_path]}"
end

options[:output_path] << '.xml' if File.extname(options[:output_path]).nil?


# loading Data
puts '== Loading Data'
data = []
CSV.read(options[:data_path]).each do |row|
  data.append [row[0..-2], row.last]
end

#training
puts '== Training'

tree = get_tree(data)

def write_tree(file, tree)
  builder = Builder::XmlMarkup.new(target: file, indent: 2)
  builder.tree(entropy: tree.entropy) do |b|
    tree.child_nodes.each do |node|
      write_node(b, node)
    end
  end
end

def write_node(builder, node)
  if node.child_nodes.count.zero?
    builder.node(node.result, entropy: node.entropy, feature: node.feature, value: node.value)
  else
    builder.node(entropy: node.entropy, feature: node.feature, value: node.value) { |b| node.child_nodes.each { |cn| write_node(b, cn) } }
  end
end


File.open(options[:output_path], 'w+') do |f|
  write_tree(f, tree)
end

puts '=== DONE'
