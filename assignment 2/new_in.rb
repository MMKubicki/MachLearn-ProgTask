require 'builder/xmlmarkup'

$VERBOSE = false

class Node
  attr_accessor :type, :entropy, :feature, :value, :child_nodes, :result

  def initialize(type)
    @type = type # tree or node
    @entropy = 0.0 # entropy at node
    @features = '' # attr.
    @value = '' # attr value
    @result = nil
    @child_nodes = [] # child nodes
  end
end


def get_tree(data)
  basic_info = {}
  basic_info[:attr] = []
  basic_info[:class] = []

  data.each do |row|
    row.first.each_with_index do |value, index|
      basic_info[:attr][index] = [] if basic_info[:attr][index].nil?
      basic_info[:attr][index].append(value) unless basic_info[:attr][index].include? value
    end

    basic_info[:class].append(row.last) unless basic_info[:class].include? row.last
  end

  tree = get_node(basic_info, data, [])
  tree.type = 'tree'
  tree
end

def get_node(basic_info, data, checked)
  node = Node.new('node')
  node.entropy = get_entropy(basic_info, data)
  puts "Entropy current node: #{node.entropy}" if $VERBOSE

  if node.entropy == 0.0
    puts "Branche done: #{data.first.last}" if $VERBOSE
    node.result = data.first.last
    return node
  end

  puts "Checked att: #{checked.sort_by { |v| v}.inspect}" if $VERBOSE

  gains = get_gains(basic_info, data, node.entropy, checked)
  puts "Gains: #{gains.inspect}" if $VERBOSE

  target = gains.max_by { |_, v| v }.first

  puts "Largest Gain: att#{target}" if $VERBOSE
  checked_next = checked.dup.append(target)


  basic_info[:attr][target].each do |set|
    new_node = get_node(basic_info, data.select { |row| row.first[target] == set}, checked_next.dup)
    new_node.feature = "att#{target}"
    new_node.value = set
    node.child_nodes.append new_node
  end

  node
end

def get_entropy(basic_info, data)
  classes = {}
  basic_info[:class].each do |c|
    classes[c] = 0.0
  end

  data.each do |row|
    classes[row.last] += 1.0
  end

  entropy = 0.0

  return entropy if data.count.zero? || classes.any? { |_, v| v == data.count.to_f }

  classes.each do |_, v|
    p = v / data.count
    entropy -= p * Math.log(p, basic_info[:class].count) unless p == 0.0
  end

  entropy
end

def get_gains(basic_info, data, entropy, checked)
  gains = {}

  to_check = Array(0..(basic_info[:attr].count - 1)) - checked
  to_check.each do |attr_nr|
    gains[attr_nr] = get_gain_attr(basic_info, data, entropy, attr_nr)
  end

  gains
end

def get_gain_attr(basic_info, data, entropy, attr_nr)
  result = entropy

  basic_info[:attr][attr_nr].each do |att_v|
    sub_data = data.select { |row| row.first[attr_nr] == att_v}
    sub_ent = get_entropy(basic_info, sub_data)
    result -= (sub_data.count.to_f / data.count.to_f) * sub_ent
  end

  result
end

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