require 'helper'
require 'gargor/cli'

describe Gargor::CLI,".start" do
  it "exits when raise ExterminationError" do
    to_load_fixture "sample-1.rb"
    Gargor.stub(:populate) { 
      raise Gargor::ExterminationError
    }
    expect{Gargor::CLI.start([])}.to raise_error(SystemExit)
  end
end
