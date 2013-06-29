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
