require 'rubygems'

module Lacquer

  def self.included(base)
    base.extend(Workshop)
  end
  
  def self.mixin(*constraints)
    DSL.find(*constraints).to_module
  end

  def self.dsl(klass_or_name, options = {})
    name = options.delete(:name) || Util.constant_to_name(klass_or_name)
    target = options.delete(:for) || (Util.constantize(Util.camelize(klass_or_name)) rescue nil)
    unless target.is_a?(Module)
      raise ArgumentError, "Invalid DSL target: #{target.inspect}"
    end
    defined = DSL.new(name, target, options)
    DSL.register(defined)
    defined
  end  

  class DSL

    def self.register(dsl)
      registry << dsl
    end

    def self.registry
      @registry ||= []
    end

    def self.find(name, version_requirement = nil)
      if name.is_a?(Symbol)
        if version_requirement
          version_requirement = Gem::Requirement.create(version_requirement)
        end
        list = registry.select { |r| r.match?(name, version_requirement) }
        list.sort_by { |dsl| dsl.version }.last
      else
        # Support lookup by hash
        registry.detect { |r| r.hash == name }
      end
    end

    attr_reader :name, :target, :constructor, :runner, :version
    def initialize(name, target, options = {})
      @name = name
      @target = target
      @constructor = lambda { |*args| target.new(*args) }
      @version = Gem::Version.create(options.delete(:version) || '1.0.0')
      @runner = Runner.new(self)
    end

    def match?(name, version_requirement = nil)
      return false unless name == @name
      if version_requirement
        version_requirement.satisfied_by?(self)
      else
        true
      end
    end

    def handlers
      @handlers ||= {}
    end

    def run(*args, &block)
      object = @constructor.call(*args)
      if block_given?
        @runner.__run__(object, &block)
      end
      object
    end

    def to_module
      mixin = Module.new
      mixin.module_eval %(
      def #{@name}(*args, &block)
        Lacquer::DSL.find(#{self.hash}).run(*args, &block)
      end
      )      
      mixin
    end

    class Runner

      def initialize(dsl)
        @dsl = dsl
      end

      def __run__(object, &block)
        @current_object = object
        instance_eval(&block)
        @current_object = nil
        object
      end

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

    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) {
          "::#{$1.upcase}"
        }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        lower_case_and_underscored_word.first.downcase +
          camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
    
    def self.underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def self.constantize(word)
      return word if !word.is_a?(String) && !word.is_a?(Symbol)
      word.split('::').inject(Object) do |parent, name|
        parent.const_get(name)
      end
    rescue NameError
      raise NameError, word    
    end
    
  end


end
