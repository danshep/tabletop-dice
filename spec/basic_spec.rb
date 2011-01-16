require "#{File.dirname(__FILE__)}/spec_helper"

describe Dice::Roll.new(5,:sides => 12), "A simple roll" do
  it "should have a string representation" do
    subject.to_s.should == '5d12'
  end
  it "should have 5 dice" do
    subject.count.should == 5
  end
  it "should have 12 sides" do
    subject.sides.should == 12
  end
  it "should create results" do
    srand(1000)
    roll = subject.roll
    roll.should be_kind_of(Dice::Result)
    roll.total.should == 33
    roll.rolls.size.should == 1
    roll.rolls.first[0].should == subject
    roll.rolls.first[1].should == [4,8,8,1,12]
  end
  it "should create random results" do
    srand(44232); subject.roll.total.should == 35
    srand(43232); subject.roll.total.should == 29
    srand(99943); subject.roll.total.should == 30
    subject.roll.total.should == 18
    subject.roll.total.should == 35
    subject.roll.total.should == 28
    subject.roll.total.should == 32
  end
end

describe "The parser" do
  it "should parse 1d6 to a roll" do
    subject = Dice.parse('1d6')
    subject.should be_kind_of(Dice::Roll)
    subject.to_s.should == '1d6'
  end
  it "should parse 5d12 to a roll" do
    subject = Dice.parse('5d12')
    subject.should be_kind_of(Dice::Roll)
    subject.to_s.should == '5d12'
  end
  it "should parse 1d6+5d12 to an addition" do
    subject = Dice.parse('1d6+5d12')
    subject.should be_kind_of(Dice::Addition)
    subject.parts.size.should == 2
    subject.parts[0].to_s.should == '1d6'
    subject.parts[1].to_s.should == '5d12'
  end
  it "should parse 1d6/2 to a division" do
    subject = Dice.parse('1d6/2')
    subject.should be_kind_of(Dice::Division)
    subject.parts.map(&:to_s).should == ['1d6','2']
  end
  it "should parse 1d6/2+2d12/3 to an addition of divisions" do
    subject = Dice.parse('1d6/2+2d12/3')
    subject.should be_kind_of(Dice::Addition)
    subject.parts.map(&:to_s).should == ['1d6/2','2d12/3']
  end
  it "should parse 1d6/2+2d12/3+1d6/2 to an addition of divisions" do
    subject = Dice.parse('1d6/2+2d12/3+1d6/2')
    subject.should be_kind_of(Dice::Addition)
    subject.parts.map(&:to_s).should == ['1d6/2','2d12/3','1d6/2']
  end
  it "should parse (1d6+3)/2 as a division of a group" do
    subject = Dice.parse('(1d6+3)/2')
    subject.should be_kind_of(Dice::Division)
    subject.parts.first.should be_kind_of(Dice::Brackets)
    subject.parts.map(&:to_s).should == ['(1d6+3)','2']
  end

    
  [
    '2d8',
    '3d8+2d6+3+1+8d8',
    '3d8-2d6+3+1+8d8',
    '-3d8',
    '1d6-1',
    '3d10/2',
    '3d10/2/4',
    '3d10*2',
    ['+2d8','2d8'],
    ['3d10 / 1d4', '3d10/1d4'],
    ['  1d6 + 33 - 2d7','1d6+33-2d7'],
    ['  1d6 - 33 + 2d7  ','1d6-33+2d7'],
  ].each do |string, expected|
    it "should parse #{string} to string #{expected||string}" do
      Dice.parse(string).to_s.should == (expected||string)
    end
  end
  [
    '2d',
    '2d3/',
    '2d3+',
    '2d3+3/4()',
    '()',
  ].each do |string|
    it "should not parse #{string}" do
      proc {Dice.parse(string)}.should raise_error(Dice::ParserError)
    end
  end
end


describe Dice::Result do
  before :each do
    #set the random number seed for consistent results
    srand(1000)
  end

  describe "A simple roll's results" do
    subject do 
      Dice.parse('1d6').roll
    end
    it { should be_kind_of(Dice::Result) }
    it { subject.rolls.size.should == 1 }
    it { subject.total.should == 4 }
    it { subject.roll_details.should == '[1d6: 4]' }
  end
  describe "An extended roll's results" do
    subject do 
      Dice.parse('3d8+2d6+3+1+8d8').roll
    end
    it { subject.rolls.size.should == 3 }
    it { subject.total.should == 59 }
    it { subject.roll_details.should == '[3d8: 4,8,8] [2d6: 1,4] [8d8: 7,5,2,6,1,2,6,1]' }
  end
  describe "An roll with negatives results" do
    subject do 
      Dice.parse('3d8-2d6-3+1+8d8').roll
    end
    it { subject.rolls.size.should == 3 }
    it { subject.total.should == 43 }
    it { subject.roll_details.should == '[3d8: 4,8,8] [-2d6: 1,4] [8d8: 7,5,2,6,1,2,6,1]' }
  end
  it "with divisors" do
    result = Dice.parse('4d10/2').roll
    result.total.should == 10
    result.roll_details.should == '[4d10: 4,8,8,1]'
  end
  it "with rolled divisors" do
    result = Dice.parse('4d10/1d4').roll
    result.total.should == 5
    result.roll_details.should == '[4d10: 4,8,8,1] [1d4: 4]'
  end
  it "with multiplier" do
    result = Dice.parse('4d10 * 2').roll
    result.total.should == 42
    result.roll_details.should == '[4d10: 4,8,8,1]'
  end
  it "with brutal" do
    result = Dice.parse('4d10r1').roll
    result.total.should == 22
    result.roll_details.should == '[4d10r1: 4,8,8,1,2]'

    result = Dice.parse('4d10r5').roll
    result.total.should == 39
    result.roll_details.should == '[4d10r5: 1,10,9,10,5,10]'
  end
  it "with keep" do
    result = Dice.parse('4d10k1').roll
    result.total.should == 8
    result.roll_details.should == '[4d10k1: 4,8,8,1]'

    result = Dice.parse('4d10k3').roll
    result.total.should == 21
    result.roll_details.should == '[4d10k3: 2,1,10,9]'
  end
  it "with grouping" do
    result = Dice.parse('(1d6+1d8+2)/2').roll
    result.total.should == 7
    result.roll_details.should == '[1d6: 4] [1d8: 8]'

    result = Dice.parse('(2d6+2)/1d4').roll
    result.total.should == 2
    result.roll_details.should == '[2d6: 1,4] [1d4: 3]'

    result = Dice.parse('(2d6+2)/(1d2+1)').roll
    result.total.should == 3
    result.roll_details.should == '[2d6: 5,2] [1d2: 2]'

    result = Dice.parse('(((((1d6))))').roll
    result.total.should == 1
    result.roll_details.should == '[1d6: 1]'
  end

end
  
