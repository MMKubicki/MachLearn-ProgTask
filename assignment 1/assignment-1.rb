script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'
require 'matrix'

# commandline parsing
options = {}
option_parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{script} [Arguments]"
  opt.separator ''
  opt.on('-h', '--help', 'Display help') do
    puts opt
    exit
  end
  opt.separator 'required Arguments:'
  opt.on('-d', '--data [FILE]', 'Path to data .csv') do |path|
    options[:data_path] = path
  end
  opt.on('-l', '--learningRate [VALUE]', 'Learning rate') do |rate|
    options[:learning_rate] = rate.to_f
  end
  opt.on('-t', '--threshold [VALUE]', 'Threshold value') do |value|
    options[:threshold] = value.to_f
  end
  opt.separator ''
  opt.separator 'optional Arguments:'
  opt.on('-o', '--output [FILE]', 'Specify output-file') do |path|
    options[:output_path] = path
  end
  opt.on('-v', '--verbose', 'Verbose output') do |v|
    options[:verbose] = v
  end
end

option_parser.parse!

# Check input
if options[:data_path].nil? || options[:learning_rate].nil? || options[:threshold].nil?
  puts "Missing Arguments. See #{script} -h"
  exit(-1)
end

unless File.file? options[:data_path]
  puts "#{options[:data_path]} doesn't exist!"
  exit(-1)
end

# preparing output file
options[:output_path] = File.basename(options[:data_path], '.*') << '_output.csv' if options[:output_path].nil?

# loading and preparing Training_data
puts 'Loading training data'

# put 1 in front of x-values, last one = result
training_data = []
CSV.read(options[:data_path]).each do |row|
  training_data.append [Vector.elements(([1].append row[0..-2].map(&:to_f)).flatten), row.last.to_f]
end

# begin-message
puts "Start training with η=#{options[:learning_rate]} and threshold=#{options[:threshold]}"
puts "Output will be saved in #{options[:output_path]}"

# sum of weight[i]*x-val[i]
def trained_func(weights, x_values)
  result = []
  x_values.each_with_index do |_, i|
    result.append(weights[i] * x_values[i])
  end
  result.sum
end

# sum of (true_result - train_func_result)^2 for every value
def error(weights, t_data)
  error = []

  t_data.each do |point|
    error.append(point.last - trained_func(weights, point.first))
  end
  error.map! { |n| n * n }.sum
end

# sum of x-values * (true-result - train_func_result)
def gradient(weights, t_data)
  result = []
  t_data.each do |point|
    result.append(point.first * (point.last - trained_func(weights, point.first)))
  end
  sum = Vector.elements(Array.new(t_data[0].first.size, 0))
  result.each do |vec|
    sum += vec
  end
  sum
end

# weights + (learning_rate * gradient)
def new_weight(weights, gradient, learning_rate)
  weights + (learning_rate * gradient)
end

# write to file
def print_output(file, iteration, weights, error)
  file << [iteration, weights.to_a, error].flatten.map { |v| v.round(4) }
end

# prepare iteration_counter and weights
iteration_counter = 0
weights = Vector.elements(Array.new(training_data[0].first.size, 0))

# open output_file
output_file = CSV.open(options[:output_path], 'w+')

# first error with weights 0
old_error = error(weights, training_data)
new_error = old_error
print_output(output_file, iteration_counter, weights, old_error)
iteration_counter += 1

# do ... until error_difference <= threshold
loop do
  # calc new weights
  weights = new_weight(weights, gradient(weights, training_data), options[:learning_rate])

  # calc new error - save old one
  old_error = new_error
  new_error = error(weights, training_data)

  puts "Iter: #{iteration_counter} | Current Error: #{new_error}" if options[:verbose] != nil

  # output
  print_output(output_file, iteration_counter, weights, new_error)
  iteration_counter += 1

  break if (old_error - new_error).abs < options[:threshold]
end

output_file.close
