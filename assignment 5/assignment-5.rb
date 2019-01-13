script = File.basename __FILE__

unless $PROGRAM_NAME == __FILE__
  puts "#{script} is script not module!"
  exit(1)
end

require 'optparse'
require 'csv'

require_relative 'functions'

options = {}

# Possible Commandline options
option_parser = OptionParser.new do |opt|
  opt.banner = "Usage 'ruby #{script} --data input.tsv --output output.tsv'"
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

puts '=== Loading Data'
t_data = []
CSV.read(options[:data_path], col_sep: "\t", converters: :float).each do |point|
  sample = create_sample(point)
  t_data.append sample
end
puts '== Done'

puts '=== Creating casebase and calculating error'
info = {}
[2, 4, 6, 8, 10].each do |k|
  ib2 = IB2.new(k)
  ib2.new_casebase(t_data)
  info[k] = {error: ib2.get_misclassified(t_data), casebase: ib2.casebase}
end
puts '== Done'

puts '=== Writing output'
CSV.open(options[:output_path], 'w+', col_sep: "\t") do |tsv_out|
  error_out = []
  info.each_pair do |_k, v|
    error_out.append v[:error].size
  end

  tsv_out << error_out

  info[4][:casebase].each do |sample|
    tsv_out << sample.values.flatten
  end
end
puts '== Done'
puts 'FINISHED'
