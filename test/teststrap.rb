require 'rubygems'
require 'riot'
require 'lacquer'

def test_class(&block)
  klass = Class.new do
    def self.name; 'Tester'; end
    include Lacquer
  end 
  klass.instance_eval(&block) if block_given?
  klass
end

def lookup(name)
  Lacquer::DSL.defined[name]
end

