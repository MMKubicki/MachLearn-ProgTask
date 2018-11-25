require 'builder/xmlmarkup'

$VERBOSE = false

class Node
  attr_accessor :type, :entropy, :feature, :value, :child_nodes, :result

  def initialize(type)
    @type = type # tree or node
    @entropy = 0.0 # entropy at node
    @features = '' # decision attribute
    @value = '' # attribute value
    @result = nil # leaf value
    @child_nodes = [] # child nodes
  end
end

# learn tree given training data 'data'
def get_tree(data)
  # get basic info about attributes and classes
  basic_info = {}
  basic_info[:attr] = [] # possible values of each attribute
  basic_info[:class] = [] # possible classes of data

  data.each do |row|
    row.first.each_with_index do |value, index|
      basic_info[:attr][index] = [] if basic_info[:attr][index].nil?
      basic_info[:attr][index].append(value) unless basic_info[:attr][index].include? value
    end

    basic_info[:class].append(row.last) unless basic_info[:class].include? row.last
  end

  # create tree
  tree = get_node(basic_info, data, [])

  # top node -> entire tree
  tree.type = 'tree'
  tree
end

# set down in recursive manner
def get_node(basic_info, data, checked)
  node = Node.new('node')

  # calculate entropy
  node.entropy = get_entropy(basic_info, data)
  puts "Entropy current node: #{node.entropy}" if $VERBOSE

  # entropy 0 -> end of branch
  # save leaf value in node and return
  if node.entropy == 0.0
    puts "Branch done: #{data.first.last}" if $VERBOSE
    node.result = data.first.last
    return node
  end

  puts "Checked att til now: #{checked.sort.inspect}" if $VERBOSE

  # calculate gains of all attributes not used yet
  gains = get_gains(basic_info, data, node.entropy, checked)
  puts "Gains: #{gains.inspect}" if $VERBOSE

  # chose highest gain
  target = gains.max_by { |_, v| v }.first

  puts "Largest Gain: att#{target}" if $VERBOSE
  checked_next = checked.dup.append(target) # add chosen attribute to checked

  # branch to every possible value of chosen attribute
  # keeping basic_info and appended checked attributes
  # reducing data to specific branch of attribute
  basic_info[:attr][target].each do |set|
    new_node = get_node(basic_info, data.select { |row| row.first[target] == set }, checked_next.dup)
    new_node.feature = "att#{target}"
    new_node.value = set
    node.child_nodes.append new_node
  end

  node
end

# current entropy of data
def get_entropy(basic_info, data)
  # get frequency of classes in current data
  classes = {}
  basic_info[:class].each do |c|
    classes[c] = 0.0
  end

  data.each do |row|
    classes[row.last] += 1.0
  end

  entropy = 0.0

  # if any class has all entries in data -> entropy == 0
  return entropy if classes.any? { |_, v| v == data.count.to_f }

  # entropy = -sum(p * log_c(p))
  classes.each do |_, v|
    p = v / data.count
    entropy -= p * Math.log(p, basic_info[:class].count) unless p == 0.0
  end

  entropy
end

# calculates gains of every attribute except those in checked
def get_gains(basic_info, data, entropy, checked)
  gains = {}

  # create all possible positions of unchecked attribute of future tree
  # and check those
  to_check = Array(0..(basic_info[:attr].count - 1)) - checked
  to_check.each do |attr_nr|
    gains[attr_nr] = get_gain_attr(basic_info, data, entropy, attr_nr)
  end

  gains
end

# calculate gain of one specific attribute in data
def get_gain_attr(basic_info, data, entropy, attr_nr)
  # gain = entropy -sum((attr_count/data_count)*entropy(attr))
  result = entropy

  basic_info[:attr][attr_nr].each do |att_v|
    sub_data = data.select { |row| row.first[attr_nr] == att_v }
    sub_ent = get_entropy(basic_info, sub_data)
    result -= (sub_data.count.to_f / data.count.to_f) * sub_ent
  end

  result
end

# write tree to xml
def write_tree(file, tree)
  # target = stream to write to
  # indent = indent in spaces
  builder = Builder::XmlMarkup.new(target: file, indent: 2)
  # first node == tree
  # step down to others
  builder.tree(entropy: tree.entropy) do |b|
    tree.child_nodes.each do |node|
      write_node(b, node)
    end
  end
end

# step down nodes
def write_node(builder, node)
  # if leaf-node -> write result of path with outer data
  if node.child_nodes.count.zero?
    builder.node(node.result, entropy: node.entropy, feature: node.feature, value: node.value)
  else
    # else write data of node and step down to children
    builder.node(entropy: node.entropy, feature: node.feature, value: node.value) { |b| node.child_nodes.each { |cn| write_node(b, cn) } }
  end
end
