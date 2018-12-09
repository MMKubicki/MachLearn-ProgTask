require 'matrix'

# Containing annealed and constant value for learning rate
class LearningRate

  attr_reader :value_const

  # Value of annealing learning rate given specified iteration
  def value_anneal_iteration(iteration)
    @value_anneal_start / iteration
  end

  # Value of annealing learning rate in current iteration of this object
  # (Specified by increment_iteration)
  def value_anneal
    value_anneal_iteration(@iteration)
  end

  # Increase iteration counter -> to be called at end of iteration
  def increment_iteration
    @iteration += 1
  end

  def initialize(start_value)
    @value_anneal_start = start_value.dup
    @iteration = 1
    @value_const = start_value.dup
  end
end

# Class for Samples
class Sample
  attr_reader :attributes, :classification

  def initialize(data)
    # replace letter with 'useful' value (result of calculation)
    @classification = data.first == 'A' ? 1 : 0
    # Attributes = Vector of Values with Attribute[0] = 1
    @attributes = Vector.elements([1.0, data[1..data.size].compact].flatten)
  end

  # Calculate Classification of this Sample given the weights
  def calc_class(weights)
    sum = weights.inner_product @attributes
    if sum > 0
      1
    else
      0
    end
  end
end

# Get all Samples which are misclassified using the weights
def get_misclass(data, weights)
  # Take data and remove any Sample which are correctly classified
  data.reject do |point|
    point.calc_class(weights) == point.classification
  end
end

# Calculate new Weights
def get_new_weights(mis_data, weights, learning_rate)
  # Take sum of learning rate * (expected classification - calculated classification) * attributes of every misclassified sample
  sum = Vector.elements(Array.new(weights.size, 0.0))
  mis_data.each do |point|
    sum += learning_rate * (point.classification - point.calc_class(weights)) * point.attributes
  end
  # New weights = old weights + sum
  weights + sum
end
