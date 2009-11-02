module Lacquer

  def self.included(base)
    base.extend(Workshop)
  end
  
  def self.[](name)
    DSL::defined[name].to_mixin
  end

  def self.dsl(klass_or_name, options = {})
    name = options.delete(:name) || Util.constant_to_name(klass_or_name)
    target = options.delete(:for) || klass_or_name
    unless target.is_a?(Module)
      raise ArgumentError, "Invalid DSL target: #{target.inspect}"
    end
    DSL.defined[name] = DSL.new(name, target, options)    
  end  

  class DSL

    def self.defined
      @defined ||= {}
    end

    attr_reader :name, :target
    def initialize(name, target, options = {})
      @name = name
      @target = target
      @options = options
    end

  end

  module Workshop

    def dsl(options = {})
      name = options.delete(:name) || Util.constant_to_name(self)
      Lacquer.dsl(self, options.merge(:name => name))
    end

  end

  module Util

    def self.constant_to_name(constant)
      return constant unless constant.is_a?(Module) or constant.is_a?(Class)
      underscore(demodulize(constant.name)).to_sym
    end

    def self.demodulize(class_name_in_module)
      class_name_in_module.to_s.gsub(/^.*::/, '')
    end

    def self.underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
    
  end


end
