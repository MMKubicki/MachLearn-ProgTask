# use sqrt as member function of float
class Float
  def sqrt
    Math.sqrt(self)
  end
end

# format input data
def create_sample(data)
  {class: data.first.upcase, position: data[1..-1]}
end

# class performing IB2
class IB2

  attr_reader :k, :casebase

  # set k of kNN
  def initialize(k)
    @k = k
    @casebase = []
  end

  # create a new codebase
  def new_casebase(t_data)
    @casebase = []
    data = t_data.dup

    # for every single sample
    until data.empty?
      entry = data.shift

      # if codebase empty just add current
      if @casebase.empty?
        @casebase.append entry.dup
        next
      end

      # else add if misclassified
      @casebase.append entry.dup if entry[:class] != eval_point(entry[:position])
    end
  end

  # get all misclassified points of input data
  def get_misclassified(data)
    misses = []

    # return sample if misclassified
    data.each do |sample|
      misses.append sample if sample[:class] != eval_point(sample[:position])
    end

    misses
  end

  # classify point on existing casebase
  def eval_point(point)
    knn = get_knn(point)

    classes = {}

    # calculate weight for every nearest neighbor
    knn.each_index do |i|
      classes[knn[i][1]] = 0 unless classes.key?(knn[i][1])

      # if nearest -> weight + 1 else use formula
      classes[knn[i][1]] +=
          if i.zero?
            1
          else
            (knn[-1][0] - knn[i][0]) / (knn[-1][0] - knn[0][0])
          end
    end

    # return class of highest weight
    classes.max_by {|_k, v| v}[0]
  end

  def get_knn(point)
    # map codebase to [distance, class]
    distance = @casebase.map {|sample| [distance(point, sample[:position]), sample[:class]]}
    # sort ascending by distance
    distance.sort_by! {|val| val[0]}

    # return first k (without nil)
    distance[0..(@k - 1)].compact
  end

  # distance between two n-dimensional points
  def distance(point1, point2)
    distance = 0
    point1.each_index do |i|
      distance += (point1[i] - point2[i]) ** 2
    end

    distance.sqrt
  end
end
