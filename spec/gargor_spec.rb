# -*- coding: utf-8 -*-
require 'helper'

describe Gargor,".start" do
  it "must initialize attributes" do
    expect(Gargor.start).to eq true
  end
end

describe Gargor,".load_dsl" do
  it "must raise RuntimeError when load from file with population 0" do
    to_load_contents ""
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
    expect(Gargor.mutate).to be_kind_of Gargor::Individual
  end
end

describe Gargor,".poplutate" do
  it "must create individuals" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    to_load_contents("{}") # dummy json
    expect(Gargor.populate.size).to be Gargor.params["population"]
    expect(Gargor.generation).to be 1
    expect(Gargor.next_generation).to be true
    expect(Gargor.generation).to be 2

    expect{
      Gargor.populate
    }.to raise_error RuntimeError
  end
end

describe Gargor,".float_rand" do
  it "returns 0...max" do
    Gargor.stub(:rand) { |max| max/2.0 }
    expect(Gargor.float_rand(0.1,100)).to eq 0.05
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
    a = Gargor.mutate; a.fitness = 0.4
    b = Gargor.mutate; b.fitness = 0.6

    expect(Gargor.crossover(a,b)).to be_kind_of Gargor::Individual
  end
end

describe Gargor,".selection" do
  it "does something" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    a = Gargor.mutate; a.fitness = 0.4
    b = Gargor.mutate; b.fitness = 0.6
    g = Gargor::Individuals.new
    g << a << b
    expect(Gargor.selection g).to be_kind_of Gargor::Individual
  end
end


describe Gargor, ".validate" do
  it "raise Gargor::GargorError unless population > 0" do
    Gargor.start
    expect{
      Gargor.validate 
    }.to raise_error Gargor::ValidationError
  end
end

describe Gargor, ".first_generation?" do
  it "returns true if not .next_generation called" do
    Gargor.start
    expect(Gargor.first_generation?).to be true
    Gargor.next_generation
    expect(Gargor.first_generation?).to be false
  end
end

describe Gargor, ".prev_count" do
  it "returns previous generation count" do
    g = Gargor::Individuals.new
    a = Gargor.mutate; a.fitness = 0.4
    g << a
    expect(Gargor.prev_count(g)).to be 1

    b = Gargor.mutate; b.fitness = 0 # not fit for this environment
    c = Gargor.mutate; c.fitness = 0.6
    g << b << c
    expect(Gargor.prev_count(g)).to be 2
  end
end

describe Gargor, ".select_elites" do
  it "returns Gargor::Individuals" do
    g = Gargor::Individuals.new
    3.times { g << Gargor.mutate }

    Gargor.start
    gg = Gargor.select_elites(g,2)
    expect(gg).to be_kind_of Gargor::Individuals
    expect(gg.count).to be 2
  end

  it "returns count of elites" do
    g = Gargor::Individuals.new
    3.times { g << Gargor.mutate }
    Gargor.start
    expect(Gargor.select_elites(g,3).count).to be 3
    expect(Gargor.select_elites(g,4).count).to be 3
  end
end

describe Gargor, ".mutaion?" do
  it "returns true by mutation probability" do
    Gargor.stub(:rand).and_return(0.05,0.15)
    expect(Gargor.mutation?(0.1)).to be true
    expect(Gargor.mutation?(0.1)).to be false
  end
end

describe Gargor, ".logfile" do
  it "return log full-path" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("/tmp/test.rb")
    expect(Gargor.logfile("gargor.log")).to eq "/tmp/gargor.log"
  end
end

describe Gargor, ".logger" do
  it "set Logger object to @@logger " do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("/tmp/test.rb")
    expect(Gargor.logger).to be_kind_of Logger
    expect(Gargor.logger.level).to be Logger::INFO
  end
end

describe Gargor, ".options=" do
  it "set options['target_nodes'] to array " do
    options = {"target_nodes" => "node1,node2,node3"}
    Gargor.options= options
    expect(Gargor.opt("target_nodes")).to be_kind_of Array
  end
end

