require 'dice/parser'
module Dice
  def self.parse(string)
    parser = Parser.new(string)
    parser.output
  end

  class Result
    attr_reader :total, :rolls
    def initialize
      @total = 0
      @rolls = []
    end
    def add(amount)
      @total += amount
    end
    def add_roll(roll, dice)
      rolls << [roll, dice]
    end
    def roll_details
      rolls.map do |roll, dice|
        "[#{roll.to_s}: #{dice.join(',')}]"
      end.join(' ')
    end
  end

  class Set
    attr_reader :parts
    def initialize(*parts)
      if Hash === parts.last 
        @options = parts.pop
      else
        @options = {}
      end
      @parts = parts
    end
    def <<(part)
      @parts << part
    end
    def negative?
      @parts.first.negative?
    end
    def roll
      result = Result.new
      results = @parts.map(&:roll)
      results.each do |r|
        result.rolls.concat(r.rolls)
      end
      result.add(calculate_total(results))
      result
    end
    def complete?
      @parts.size >= 2
    end
    def self.after?(other_object)
      return false unless other_object
      precedence = [Multiplication,Division,Addition,Brackets] 
      precedence.index(self) > precedence.index(other_object.class)
    end
  end

  class Brackets < Set
    def <<(part)
      raise 'brackets should have only one part' unless @parts.empty?
      super
    end
    def negative?
      @options[:negative]
    end
    def calculate_total(results)
      results.first.total
    end
    def complete?
      @parts.size == 1
    end
    def to_s
      "#{'-' if negative?}(#{@parts.first.to_s})"
    end
  end


  class Addition < Set
    def calculate_total(results)
      results.inject(0) {|s,r| s+r.total }
    end
    def to_s
      i = -1
      @parts.map do |p|
        i+=1
        if p.negative? || i ==0
          p.to_s
        else
          "+" + p.to_s
        end
      end.join
    end
  end

  class Constant
    attr_reader :value
    def initialize(value)
      @value = value
    end
    def negative?
      value < 0
    end
    def complete?
      true
    end
    def roll(result=Result.new)
      result.add(value)
      result
    end
    def to_s
      @value.to_s
    end
  end

  class Multiplication < Set
    def calculate_total(results)
      results.inject(1) {|s,r| s*r.total}
    end
    def to_s
      @parts.join('*')
    end
  end

  class Division < Set
    def calculate_total(results)
      results.inject(nil) {|s,r| s ? s/r.total : r.total }
    end
    def to_s
      @parts.join('/')
    end
  end

  class Roll
    attr_reader :count, :options
    def initialize(count, options={})
      @count, @options = count, options
      raise 'Must specify :sides' unless options[:sides]
      raise 'Brutal must be < sides' if options[:brutal] && options[:brutal] >= options[:sides]
    end
    def sides
      @options[:sides]
    end
    def complete?
      true
    end
    def negative?
      @options[:negative]
    end
    def brutal
      @options[:brutal] || 0
    end
    def roll(result=Result.new)
      dice = []
      total = 0
      count.times do
        value = 0
        begin
          value = rand(sides)+1
          dice << value
        end while value <= brutal
        total += value
      end
      if options[:keep]
        total = dice.sort[-options[:keep]..-1].inject(0){|s,x| s+x}
      end
      result.add_roll(self, dice)
      result.add(negative? ? -total : total)
      result
    end
    def to_s
      s = "#{'-' if negative?}#{count}d#{sides}"
      s += "r#{brutal}" if brutal > 0
      s += "k#{options[:keep]}" if options[:keep]
      s
    end
  end

end
