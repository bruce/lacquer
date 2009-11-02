require 'teststrap'

context "Defining a DSL" do

  setup do
    Lacquer::DSL.defined.clear
    test_class
  end

  context "normally" do    
    setup { topic.dsl }
    topic.exists
    topic.assigns(:name, :tester)
    should("register it globally") { lookup topic.name }.exists
  end

  context "with a custom name" do
    setup { topic.dsl :name => :custom }
    topic.exists
    topic.assigns(:name, :custom)
    should("register it globally") { lookup topic.name }.exists
  end

  context "with multiple" do
    setup do
      topic.dsl
      topic.dsl :name => :custom
    end
    should("define both") { Lacquer::DSL.defined.size }.equals(2)
  end  

  context "from the Lacquer module" do

    context "with a target class argument" do
      setup { Lacquer.dsl(@target = topic) }
      topic.exists
      topic.assigns(:name, :tester)
      topic.assigns(:target, @target)
      should("register it globally") { lookup topic.name }.exists
    end

    context "with a DSL name argument" do
      
      context "matching a target class" do
        setup { Lacquer.dsl File }
        topic.exists
        topic.assigns(:name, :file)
        topic.assigns(:target, File)
        should("register it globally") { lookup topic.name }.exists
      end
      
      context "passing a manual :for option" do
        setup { Lacquer.dsl :something, :for => File }
        topic.exists
        topic.assigns(:name, :something)
        topic.assigns(:target, File)
        should("register it globally") { lookup topic.name }.exists
      end
      
      context "not matching a target class or passing a manual :for option" do
        should("not work") { Lacquer.dsl :does_not_exist }.raises(ArgumentError)
        should("not register it globally") { lookup :does_not_exist }.nil
      end

    end
    
  end
  
end  

    
