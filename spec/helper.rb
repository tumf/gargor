# -*- coding: utf-8 -*-
$TESTING=true

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'gargor'
require 'rspec'
RSpec.configure do |config|
end

def load_fixture name
  file = File.join(File.dirname(__FILE__), "fixtures",name)
  File.open(file) { |f| f.read }
end

def to_load_fixture name
  File.stub(:read).and_return(load_fixture(name))
end

def to_load_contents text
  File.stub(:read).and_return(text)
end
