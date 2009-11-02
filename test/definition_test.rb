require 'teststrap'

context "Defining a DSL" do

  setup do
    reset
    Photo
  end

  context "normally" do
    setup { topic.dsl }
    topic.kind_of(Lacquer::DSL)
    topic.assigns(:name, :photo)
    should("register it globally") { lookup topic.name }.exists
  end

  context "with a custom name" do
    setup { topic.dsl :name => :custom }
    topic.kind_of(Lacquer::DSL)
    topic.assigns(:name, :custom)
    should("register it globally") { lookup topic.name }.exists
  end

  context "with multiple" do
    setup do
      topic.dsl
      topic.dsl :name => :custom
    end
    should("register all") { Lacquer::DSL.registry.size }.equals(2)
  end  

  context "from the Lacquer module" do

    context "with a target class argument" do
      setup { Lacquer.dsl Photo }
      topic.kind_of(Lacquer::DSL)
      topic.assigns(:name, :photo)
      topic.assigns(:target, @target)
      should("register it globally") { lookup topic.name }.exists
    end

    context "with a DSL name argument" do
      
      context "matching a target class" do
        setup { Lacquer.dsl :photo }
        topic.kind_of(Lacquer::DSL)
        topic.assigns(:name, :photo)
        topic.assigns(:target, Photo)
        should("register it globally") { lookup topic.name }.exists
      end
      
      context "passing a manual :for option" do
        setup { Lacquer.dsl :something, :for => Photo }
        topic.kind_of(Lacquer::DSL)
        topic.assigns(:name, :something)
        topic.assigns(:target, Photo)
        should("register it globally") { lookup topic.name }.exists
      end
      
      context "not matching a target class or passing a manual :for option" do
        should("not work") { Lacquer.dsl :does_not_exist }.raises(ArgumentError)
        should("not register it globally") { lookup :does_not_exist }.nil
      end

    end
    
  end
  
end  

    
