require 'teststrap'

context "Using a DSL" do

  setup do
    reset
    Photo.dsl :version => '1.1'
    Photo.dsl :version => '1.0'
  end

  context "including DSL mixin without a constraint" do
    should("not raise an exception") { sandbox { include Lacquer.mixin(:photo) } }.exists
    should("provide the entry point") do
      Lacquer.mixin(:photo).instance_methods.include?("photo")
    end
    should("construct an instance") {
      result = nil
      sandbox {
        class << self
          include Lacquer.mixin(:photo)
        end
        result = photo { }
      }
      result
    }.kind_of(Photo)
  end

end

