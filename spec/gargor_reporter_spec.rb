require 'helper'
require 'gargor/reporter'

describe Gargor::OptimizeReporter, '.table' do
  before do
    to_load_fixture 'sample-1.rb'
    Gargor.start
    Gargor.load_dsl('dummy')
    @a = Gargor.mutate
    @b = Gargor.mutate
  end

  it 'return Terminal::Table object' do
    expect(Gargor::OptimizeReporter.table(@a, @b)).to be_kind_of Terminal::Table
  end
end
