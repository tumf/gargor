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

def load_fixture name
  file = File.join(File.dirname(__FILE__), "fixtures",name)
  File.open(file).read
end

def to_load_fixture name
  file = double("DSL file")
  file.stub(:read).and_return(load_fixture(name))
  File.stub(:open).and_return file
end

def to_load_contents text
  file = double("DSL file")
  file.stub(:read).and_return(text)
  File.stub(:open).and_return file
end
