require 'helper'

describe Gargor,"VERSION" do
  it "must be {major}.{minor}.{patch}" do
    expect(Gargor::VERSION).to match /\d+\.\d+\.\d+/
  end
end
