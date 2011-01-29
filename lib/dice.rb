require 'dice/parser'
module Dice
  def self.parse(string)
    parser = Parser.new(string)
    parser.output
  end

  def self.random_number(max)
    number_generator.rand(max)
  end

  def self.number_generator
    @number_generator ||= Kernel
  end
  def self.number_generator=(value)
    @number_generator = value
  end

  def self.with_fixed_rolls(results, &block)
    old_generator = self.number_generator
    generator = Object.new
    class << generator
      attr_writer :numbers
      def rand(max)
        result = @numbers.shift
        raise 'More rolls than expected' unless result
        raise 'Fixed result is greater than dice sides' if result >= max
        result - 1
      end
    end
    generator.numbers = results
    begin
      self.number_generator = generator
      block.call
    ensure
      self.number_generator = old_generator
    end
  end

  class Result
    attr_reader :total, :rolls
    def initialize
      @total = 0
      @rolls = RollCache.new 
    end
    def add(amount)
      @total += amount
    end
    def add_roll(roll, dice)
      rolls.add(roll, dice)
    end
    def roll_details
      rolls.to_s
    end
  end
  class RollCache
    attr_reader :rolls
    def initialize
      @rolls = []
    end
    def add(roll, dice)
      @rolls << [roll, dice]
    end
    def size
      @rolls.size
    end
    def concat(other_cache)
      @rolls.concat(other_cache.rolls)
    end
    def [](index)
      roll, dice = @rolls[index]
      dice
    end
    def get(roll)
      roll, dice = @rolls.assoc(roll)
      dice
    end
    def to_s
      @rolls.map do |roll, dice|
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
    def roll(roll_options={})
      result = Result.new
      results = @parts.map {|r| r.roll(roll_options) }
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
  class AttributeError < StandardError; end
  class Function < Brackets
    attr_reader :name
    def initialize(name, *args)
      @name = name
      super(*args)
    end
    def roll(roll_options={})
      lookup = roll_options[:attributes]
      raise AttributeError.new "No attribute values found" unless lookup
      value = lookup[name]
      if value && (!(Numeric === value) || value > 0)
        super
      else
        Result.new
      end
    end  
    def to_s
      "#{'-' if negative?}#{name}(#{@parts.first.to_s})"
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

  class Lookup
    attr_reader :key
    def initialize(key, options={})
      @key, @options = key, options
    end
    def complete?
      true
    end
    def roll(roll_options={})
      lookup = roll_options[:attributes]
      raise AttributeError.new "No attribute values found" unless lookup
      value = lookup[@key]
      raise AttributeError.new "Unknown attribute #{key}" if value.nil?
      result = Result.new
      result.add(value)
      result
    end
    def negative?
      @options[:negative]
    end
    def to_s
      "#{'-' if negative?}#{key}"
    end
  end

  class Constant
    attr_reader :value
    def initialize(value)
      @value = value
    end
    def complete?
      true
    end
    def roll(roll_options={})
      result = Result.new
      result.add(value)
      result
    end
    def negative?
      @value < 0
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
    def roll(roll_options={})
      result=Result.new
      dice = roll_options[:roll_cache].get(self) if roll_options[:roll_cache]
      unless dice
        dice = []
        count.times do
          dice << Dice.random_number(sides-brutal)+1+brutal
        end
      end
      if options[:keep]
        total = dice.sort[-options[:keep]..-1].inject(0){|s,x| s+x}
      else
        total = dice.inject(0){|s,x| s+x}
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
