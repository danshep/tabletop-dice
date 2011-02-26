module Dice
  class ParserError < StandardError;end
  class Parser
    SPACE = ' '[0]
    def initialize(string)
      #p ['parsing', string]
      @stack = []
      @string = string
      @index = -1
      state_start
    end
    def output
      @stack.first
    end
    private
      def next_char
        @string[@index+=1]
      end
      def unexpected(c)
        if c
          error("Unexpected character #{c.chr}")
        else
          error('Unexpected end of string')
        end
      end
      def error(string)
        message = "Error at char #{@index}: #{string}"
        message += "\n#{@string}"
        message += "\n" + " " * @index + "^"
        raise ParserError.new(message)
      end
      def state_start(c = next_char)
        @options = {}
        case c
        when ?+ then
          state_start_roll
        when ?- then
          @options[:negative] = true
          state_start_roll
        when SPACE then state_start
        when nil
          validate_end
        else               state_start_roll(c)
        end
      end
      def state_start_roll(c = next_char)
        case c
        when (?1..?9) then 
          @count = c - ?0
          state_parse_count
        when SPACE then state_start_roll
        when ?(
          @stack << Brackets.new
          state_start_roll
        when (?a..?z), (?A..?Z)
          @attribute = c.chr
          state_parse_attribute
        else unexpected(c)
        end
      end
      def state_parse_attribute(c = next_char)
        case c
        when (?a..?z), (?A..?Z), ?_
          @attribute += c.chr
          state_parse_attribute
        when ?(
          @stack << Function.new(@attribute, @options)
          state_start_roll
        else
          @calc = Lookup.new(@attribute, @options)
          state_end_roll(c)
        end
      end
      def state_parse_count
        case c = next_char
        when (?0..?9) then
          @count = @count * 10 + (c - ?0)
          state_parse_count
        when ?d, ?D then 
          @option_name = :sides
          state_start_option_value
        #when ?+, ' '[0], ?-, nil
        else
          @calc = Constant.new(@options[:negative] ? -@count : @count)
          state_end_roll(c)
        #else unexpected(c)
        end
      end
      def state_start_option_value
        case c = next_char
        when (?1..?9) then
          @option_value = c - ?0
          state_parse_option_value
        else unexpected(c)
        end
      end
      def state_parse_option_value
        c = next_char
        if (?0..?9) === c then
          @option_value = @option_value * 10 + (c - ?0)
          state_parse_option_value
        else
          @options[@option_name] = @option_value
          case c
          when ?r
            @option_name = :brutal
            state_start_option_value
          when ?k
            @option_name = :keep
            state_start_option_value
          else
            @calc = Roll.new(@count, @options)
            state_end_roll(c)
          end
        end
      end
      def validate_end
        unless @stack.size == 1 && @stack.last.complete?
          unexpected(nil) 
        end
      end
      def state_end_roll(c = next_char)
        #p ['end roll', @calc]
        case c
        when SPACE
          state_start_type
        else
          state_next_part(c)
        end
      end
      def state_next_part(c = next_char)
        case c
        when nil
          add_element @calc, nil
          validate_end
        when ?+, ?-
          add_element @calc, Addition
          state_start(c) if c
        when ?* 
          add_element @calc, Multiplication
          state_start
        when ?/
          add_element @calc, Division
          state_start
        when ?)
          add_element @calc, nil
          if Brackets === @stack.last
            @calc = @stack.pop
            state_end_roll
          else
            unexpected(c)
          end
        else unexpected(c)
        end
      end
      def state_start_type(c = next_char)
        case c
        when (?a..?z), (?A..?Z), ?_
          @damage_type = c.chr
          state_parse_type
        else
          state_end_roll(c)
        end
      end
      def state_parse_type(c = next_char)
        case c
        when (?a..?z), (?A..?Z), ?_
          @damage_type += c.chr
          state_parse_type
        else
          state_continue_type(c)
        end
      end
      def state_end_type(c = next_char)
        case c
        when SPACE
          state_continue_type
        else
          add_element @calc, TypedSet, :damage_type => @damage_type
          @calc = @stack.pop
          state_next_part(c)
        end
      end
      def state_continue_type(c = next_char)
        case c
        when SPACE
          state_continue_type
        when ?a
          return unexpected(c) unless ?n === (c = next_char)
          return unexpected(c) unless ?d === (c = next_char)
          return unexpected(c) unless SPACE === (c = next_char)
          c = next_char while c == SPACE
          return unexpected(c) unless (?a..?z) === c || (?A..?Z) === c || ?_ === c
          @damage_type += ' and '
          state_parse_type(c)
        else
          state_end_type(c)
        end
      end
      def add_element(element, set_class, *args)
        #p ['adding   ', set_class, element.to_s]
        if(@stack.empty?)
          @stack << (set_class ? set_class.new(element, *args) : element)
        elsif set_class.nil?
          @stack.last << element
          while @stack.size > 1 && !(Brackets === @stack.last)
            pop = @stack.pop
            @stack.last << pop
          end
        else
          while set_class.after?(@stack.last)
            @stack.last << element
            element = @stack.pop
          end
          if(@stack.last && @stack.last.class == set_class)
            @stack.last << element
          else
            new = set_class.new(element, *args)
            @stack << new
          end
        end
        #p ['new stack', @stack.map(&:to_s)]
      end
  end
end
