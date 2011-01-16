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
    roll.rolls[0].should == [4,8,8,1,12]
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
  it "should create the same results when passed a results object" do
    srand(44232);
    result = subject.roll
    result.total.should == 35
    subject.roll(:roll_cache => result.rolls).total.should == 35
    subject.roll(:roll_cache => result.rolls).total.should == 35
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
  it "should parse an attribute" do
    subject = Dice.parse('monkey')
    subject.should be_kind_of(Dice::Lookup)
    subject.key.should == 'monkey'
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

shared_examples_for "a valid dice string" do |total, roll_details, roll_options|
  before :each do
    #set the random number seed for consistent results
    srand(1000)
  end
  subject { Dice.parse(dice).roll(roll_options||{}) }
  it { should be_kind_of(Dice::Result) }
  its(:total) { should == total }
  its(:roll_details) { should == roll_details }
end

  
describe Dice::Result do
  def self.describe_dice(dice, total, roll_details, roll_options={}, &block)
    describe "result for #{dice}" do
      subject { srand(1000); Dice.parse(dice).roll(roll_options) }
      it { should be_kind_of(Dice::Result) }
      its(:total) { should == total }
      its(:roll_details) { should == roll_details }
      instance_eval(&block) if block
    end
  end
  before(:each) { srand(1000) }
  context "basic dice" do
    describe_dice "1d6", 4, '[1d6: 4]'
    describe_dice "3d8+2d6+3+1+8d8", 59, '[3d8: 4,8,8] [2d6: 1,4] [8d8: 7,5,2,6,1,2,6,1]'
    describe_dice "3d8-2d6-3+1+8d8", 43, '[3d8: 4,8,8] [-2d6: 1,4] [8d8: 7,5,2,6,1,2,6,1]'
  end
  context "with divisors" do
    describe_dice "4d10/2", 10, '[4d10: 4,8,8,1]'
    describe_dice "4d10/2/3", 3, '[4d10: 4,8,8,1]'
    describe_dice "4d10/1d4", 5, '[4d10: 4,8,8,1] [1d4: 4]'
  end
  context "with multipliers" do
    describe_dice "4d10 * 2", 42, '[4d10: 4,8,8,1]'
    describe_dice "4d10*1d4", 84, '[4d10: 4,8,8,1] [1d4: 4]'
  end
  context "with brutal" do
    describe_dice "4d10r1", 25, '[4d10r1: 5,9,9,2]'
    describe_dice "4d10r5", 34, '[4d10r5: 9,6,9,10]'
  end
  context "with keep" do
    describe_dice "4d10k1", 8, '[4d10k1: 4,8,8,1]'
    describe_dice "4d10k3", 20, '[4d10k3: 4,8,8,1]'
  end
  context "with grouping" do
    describe_dice "(1d6+1d8+2)/2", 7, '[1d6: 4] [1d8: 8]'
    describe_dice "(2d6+2)/1d4", 1, '[2d6: 4,1] [1d4: 4]'
    describe_dice "(2d6+2)/(1d2+1)", 2, '[2d6: 4,1] [1d2: 2]'
    describe_dice "(((1d6)))", 4, '[1d6: 4]'
  end
  context "with an attribute" do
    describe_dice "testa+2+testb", 8, "", :attributes => {'testa' => 1, 'testb' => 5}
    it "should raise if no lookup is passed" do
      proc { Dice.parse('testa').roll }.should raise_error(Dice::AttributeError)
    end
    it "should raise if attribute is nil" do
      proc { Dice.parse('testa').roll(:attributes => {'testa' => nil}) }.should raise_error(Dice::AttributeError)
    end
  end
  context "with a function" do
    describe_dice "testa(1d6)+5", 5, "", :attributes => {'testa' => false }
    describe_dice "testa(1d6)+5", 5, "", :attributes => {'testa' => 0 }
    describe_dice "testa(1d6)+5", 9, "[1d6: 4]", :attributes => {'testa' => true }
    describe_dice "testa(1d6)+5", 9, "[1d6: 4]", :attributes => {'testa' => 5 }
    it "should raise if no lookup is passed" do
      proc { Dice.parse('testa(5)').roll }.should raise_error(Dice::AttributeError)
    end
    it "should not raise if attribute is nil" do
      proc { Dice.parse('testa(5)').roll(:attributes => {'testa' => nil}) }.should_not raise_error(Dice::AttributeError)
    end
  end

end
  
