# -*- coding: utf-8 -*-
require 'helper'

describe Gargor,".start" do
  it "must initialize attributes" do
    expect(Gargor.start).to eq true
  end
end

describe Gargor,".load_dsl" do
  it "must raise RuntimeError when load from file with population 0" do
    File.stub_chain(:open,:read).and_return ""
    Gargor.start
    expect {
      Gargor.load_dsl("dummy")
    }.to raise_error(RuntimeError)
  end

  it "must load DSL successfully from sample-1.rb file" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    expect(Gargor.load_dsl("dummy")).to be true
    expect(Gargor.params["population"]).to be 10

    to_load_contents "population 100"
    expect(Gargor.load_dsl("dummy")).to be true
    expect(Gargor.params["population"]).to be 100
  end

  it "must raise NoMethodError when unknown command" do
    Gargor.start
    to_load_contents "hoge 100"
    expect {
      Gargor.load_dsl("dummy")
    }.to raise_error(NoMethodError)
  end

end

describe Gargor,".mutation" do
  it "must create individual" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    expect(Gargor.mutation).to be_kind_of Gargor::Individual
  end
end

describe Gargor,".poplutate" do
  it "must create individuals" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    to_load_contents("{}") # dummy json
    expect(Gargor.populate.size).to be Gargor.params["population"]
    expect(Gargor.opt("generation")).to be 1
    expect(Gargor.next_generation).to be true
    expect(Gargor.opt("generation")).to be 2

    expect{
      Gargor.populate
    }.to raise_error RuntimeError
  end
end

describe Gargor,".float_rand" do
  it "returns 0...max" do
    Gargor.stub(:rand) { |max| max/2.0 }
    expect(Gargor.float_rand(0.1,100)).to be 0.05
  end

  it "raise RuntimeError unless max > 0" do
    expect {
      Gargor.float_rand(0)}.to raise_error RuntimeError
    expect {
      Gargor.float_rand(-1.2)}.to raise_error RuntimeError
  end
end

describe Gargor,".crossover" do
  it "crossoveres two Gargor::Individual objects" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    a = Gargor.mutation; a.fitness = 0.4
    b = Gargor.mutation; b.fitness = 0.6

    expect(Gargor.crossover(a,b)).to be_kind_of Gargor::Individual
  end
end

describe Gargor,".selection" do
  it "does something" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    a = Gargor.mutation; a.fitness = 0.4
    b = Gargor.mutation; b.fitness = 0.6
    g = [a,b]
    expect(Gargor.selection g).to be_kind_of Gargor::Individual
  end
end



