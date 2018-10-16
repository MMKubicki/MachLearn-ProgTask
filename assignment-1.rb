script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'

# commandline parsing
options = {}
option_parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{script} [Arguments]"
  opt.separator ''
  opt.on('-h', '--help', 'Display help') do
    puts opt
  end
  opt.separator 'required Arguments:'
  opt.on('-d', '--data FILE', 'Path to data .csv') do |path|
    options[:data_path] = path
  end
  opt.on('-l', '--learningRate VALUE', 'Learning rate') do |rate|
    options[:learning_rate] = rate.to_f
  end
  opt.on('-t', '--threshold VALUE', 'Threshold value') do |value|
    options[:threshold] = value.to_f
  end
  opt.separator ''
  opt.separator 'optional Arguments:'
  opt.on('-o', '--output [FILE]', 'Specify output-file') do |path|
    options[:output_path] = path
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

# loading
puts 'Loading training data'

training_data = []
CSV.read(options[:data_path]).each do |row|
  training_data.append [row[0..-2], row.last]
end

# begin-message
puts "Start training with η=#{options[:learning_rate]} and threshold=#{options[:threshold]}"
puts "Output will be saved in #{options[:output_path]}"

output_file = CSV.open(options[:output_path], 'w+')



output_file.close
