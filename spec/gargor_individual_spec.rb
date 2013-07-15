require 'helper'

describe Gargor::Individual,"#load_now" do
  it "returns self" do
    expect(Gargor::Individual.new.load_now).to be_kind_of Gargor::Individual
  end
end

describe Gargor::Individual, "#set_params" do
  
end

describe Gargor::Individual, "#deploy" do
  before do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")

    @i = Gargor.mutate
  end

  it "build collect command-line" do
    @i.stub(:shell) { |cmd|
      expect(cmd).to match /knife solo cook (www-1|www-2|db-1).example/
      ["",0]
    }
    expect(@i.deploy).to be true
  end

  it "raise Gargor::DeployError if deploy failed" do
    @i.stub(:shell) { |cmd|
      ["",255]
    }
    expect{@i.deploy}.to raise_error Gargor::DeployError
    
  end
end

describe Gargor::Individual, "attack" do
  it "build collect attack command" do
    to_load_fixture "sample-1.rb"
    Gargor.start
    Gargor.load_dsl("dummy")
    i = Gargor.mutate
    i.stub(:shell) { |cmd|
      expect(cmd).to eq Gargor.opt("attack_cmd")
      out=<<EOF
abc, 3300 req/s
FAILED 0
EOF
      [out,0]
    }
    i.attack
    expect(i.fitness).to eq 3300.0

  end
end
