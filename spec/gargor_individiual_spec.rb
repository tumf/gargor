require 'helper'

describe Gargor::Individual,"#load_now" do
  it "returns self" do
    expect(Gargor::Individual.new.load_now).to be_kind_of Gargor::Individual
  end
end
