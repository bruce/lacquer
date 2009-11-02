require 'rubygems'
require 'riot'
require 'lacquer'

class Photo
  include Lacquer

  attr_accessor :caption
  def initialize(caption = nil, metadata = {})
    @caption = caption
    @metadata = metadata
    @people = []        
  end

  def [](key)
    @metadata[key]
  end

  def add_person(name)
    person = name.is_a?(Person) ? name : Person.new(name)
    people << person
    person
  end

end

class Person
  include Lacquer
  
  attr_accessor :age
  def initialize(name)
    @name = name
  end

end

# Protect the enclosing scope from module inclusions
def sandbox(&block)
  Module.new(&block)
end

def reset
  Lacquer::DSL.registry.clear
end

def lookup(*args)
  Lacquer::DSL.find(*args)
end

