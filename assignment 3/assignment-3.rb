script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'
require 'matrix'

# Used functions in functions.rb
require_relative 'functions'

options = {}
options[:iteration] = 100
options[:learning_rate] = 1.0

# Possible Commandline options
option_parser = OptionParser.new do |opt|
  opt.banner = "Usage 'ruby #{script} [Arguments]'"
  opt.separator ''
  opt.on('-h', '--help', 'Display help') do
    puts opt
    exit
  end
  opt.separator ''
  opt.separator 'required Arguments:'
  opt.on('-d', '--data [FILE]', 'Path to data .tsv') do |path|
    options[:data_path] = path
  end
  opt.on('-o', '--output [FILE]', 'Path to output .tsv. Will be overwritten') do |path|
    options[:output_path] = path
  end
  opt.separator ''
  opt.separator 'optional Arguments:'
  opt.on('-i', '--max-iter [ITERATIONS]', 'Max number of iterations') do |iter|
    options[:iteration] = iter
  end
  opt.on('-l', '--learning-rate [RATE]', 'Learning rate for constant and initial for annealing') do |value|
    options[:learning_rate] = value.to_f
  end
  opt.on('-v', '--verbose', 'Write a lot of information to terminal') do
    $VERBOSE = true
  end
end

option_parser.parse!

# Check given arguments required to run
if options[:data_path].nil?
  puts "Missing Arguments. See #{script} -h"
  exit(-1)
end

# Check if Input exists
unless File.file? options[:data_path]
  puts "#{options[:data_path]} doesn't exist!"
  exit(-1)
end

# Set an output if not given
if options[:output_path].nil?
  options[:output_path] = File.basename(options[:data_path], '.*') << '_output.tsv'
  puts "No output specified. Writing to #{options[:output_path]}"
else
  puts "Writing output to #{options[:output_path]}"
end

# loading Data
# Result is Array of Sample-objects
puts '=== Loading Data'
data = []
CSV.read(options[:data_path], col_sep: "\t", converters: :float).each do |point|
  sample = Sample.new(point)
  data.append sample
  puts "Read sample:\n\tClass: #{sample.classification}\n\tAttributes: #{sample.attributes.inspect}" if $VERBOSE
end

# Set learning rate and start values for weights
learning_rate = LearningRate.new(options[:learning_rate])
puts "Learning Rate: #{learning_rate.value_const}" if $VERBOSE
weights_const = Vector.elements(Array.new(data.first.attributes.size, 0.0))
weights_anneal = Vector.elements(Array.new(data.first.attributes.size, 0.0))
puts "Initial Weights: #{weights_const.inspect}" if $VERBOSE

# List for errors each iteration
error_const = []
error_anneal = []

puts '== Done: Loading Data'

puts '=== Training'
(1..options[:iteration]).each do |iter|
  # const learning rate
  # Get misclassified samples using weights calculated with constant learning rate
  mis_const = get_misclass(data, weights_const)
  puts "Number misclassified const: #{mis_const.size}" if $VERBOSE
  # error = number of misclassified samples
  error_const.append mis_const.size

  # calculate new weights using misclassified samples, old weights and learning rate
  weights_const = get_new_weights(mis_const, weights_const, learning_rate.value_const)
  puts "New weights const: #{weights_const.inspect}" if $VERBOSE
  # anneal
  # same as const but using annealing learning rate with given iteration
  mis_anneal = get_misclass(data, weights_anneal)
  puts "Number misclassified annealing: #{mis_anneal.size}" if $VERBOSE
  error_anneal.append mis_anneal.size

  weights_anneal = get_new_weights(mis_anneal, weights_anneal, learning_rate.value_anneal)
  puts "New weights annealing: #{weights_anneal.inspect}" if $VERBOSE
  learning_rate.increment_iteration
end

# final error
error_const.append get_misclass(data, weights_const).size
error_anneal.append get_misclass(data, weights_anneal).size

puts "Final error:\n\tConst: #{error_const.last}\n\tAnnealing: #{error_anneal.last}" if $VERBOSE

puts '== Done: Training'

puts '=== Writing Output'
# first line error using const learning rate; second line annealing learning rate
puts "Writing to #{options[:output_path]}" if $VERBOSE
CSV.open(options[:output_path], 'w+', col_sep: "\t") do |tsv_out|
  tsv_out << error_const
  tsv_out << error_anneal
end
puts '== Done: Writing Output'
