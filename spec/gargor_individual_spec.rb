require 'helper'

describe Gargor::Individual,"#load_now" do
  it "returns self" do
    expect(Gargor::Individual.new.load_now).to be_kind_of Gargor::Individual
  end
end

describe Gargor::Individual, "#set_params" do
  
end

describe Gargor::Individual, "#deploy" do
  it "build collect command-line" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")

    i = Gargor.mutation
    i.stub(:system) { |cmd|
      expect(cmd).to match /knife solo cook (www-1|www-2|db-1).example/
    }
    i.deploy
  end
end

describe Gargor::Individual, "attack" do
  it "build collect attack command" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    i = Gargor.mutation
    i.stub(:shell) { |cmd|
      expect(cmd).to eq Gargor.opt("attack_cmd")
      out=<<EOF
abc, 3300 req/s
FAILED 0
EOF
      [out,"0"]
    }
    i.attack
    expect(i.fitness).to eq 3300.0

  end
end
