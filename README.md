# Lacquer

Define DSL-style APIs to configure Ruby objects.

## Installation

Install from gemcutter.

Either set-up gemcutter as your default gem source:

    $ sudo gem install gemcutter
    $ gem tumble

Then install:

    $ sudo gem install lacquer

Or, install in a one-liner:

    $ sudo gem install lacquer --source http://gemcutter.org

## Example

For the sake of this example, let's assume we have a Photo class that
models a photograph. Instances have a caption and include a list of
people shown in the photo as well as a hash of camera and
post-processing metadata from the photographer.

    class Photo

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

### Motivations for using Lacquer

We'd like to support a DSL that allows people to configure Photo (and
related Person) instances in a simple, declarative way.

We could easily modify methods like `initialize` and `add_person`
to accept blocks and `yield` or `instance_eval` as necessary, but
we'll use Lacquer instead for a few reasons:

1. We'd like to modify the Photo class in the future and stay
   backwards compatible with existing uses of the DSL -- without
   littering the class with obsolete/deprecated methods.
2. We'd like to support multiple versions of the DSL simultaneously
3. We'd like to generate documentation on the DSL (separate from
   normal object API documentation)

Using Lacquer decouples the definition of the DSL from the underlying
class implementation.  It makes your DSL a first-class citizen.

### Where to define a DSL

You can define a DSL two different ways:

1. From directly within the class definition (either normal or re-opened):

       class Photo
         include Lacquer::DSL
         
         dsl :version => '1.0' do
           # DSL definition goes here...
         end
       end

2. From the Lacquer module itself, separate of the class definition:

       Lacquer.dsl Photo, :version => '1.0' do
         # DSL definition goes here...
       end

Note: The version argument, shown above, is optional, but
recommended.  The default version is '1.0', if not given.

### How to use the DSL

Once you've defined a DSL for a class, you can use it anywhere.  All
you need to do is `include` the DSL module definition.

Using our example above, this could be done using one of the following:

1. Include the DSL module defined for the class: 

       include Photo::DSL

       photo do
         # use the DSL
       end

2. Include the DSL module defined for the class (looking it up using
   the Lacquer module's `DSL` utility):

       include Laquer::DSL(Photo)

       photo do
         # use the DSL
       end

Note: I explain how to use DSL with `yield` instead of `instance_eval`
semantics in the "Yield instead Instance Eval" section at the bottom
of the README.  I use the `instance_eval` form in this document for
brevity.

#### DSL names and entry points

You'll notice that in both of these examples, a `photo` method is
what's provided by the module inclusion.  This is what Lacquer refers
to as the DSL "name" (and, when used as a method, the "entry point").
While the DSL name is usually automatically derived from the target
class name (in this example, `Photo`), it can be manually set when
defining the DSL by providing a `:name` option.  For example, if we
defined the DSL using the following:

    dsl :version => '1.0', :name => 'snap'

Then, after including the module, we could use:

    snap do 
      # use the DSL
    end

A side benefit of the ability to choose a different DSL name manually
is that, since the `Lacquer::DSL` method also supports lookup using it,
eg:

    include Lacquer::DSL(:photo)

We could later, after refactoring, move the "photo" DSL to an entirely
different class, and maintain backwards compatibility.

    class Snapshot
      include Lacquer::DSL

      dsl :version => '1.0', :name => 'photo' do
        # Modified DSL definition to create a "Snapshot" instance now
      end

      # Newer DSL definitions

    end

### How to define the DSL

Now let's talk about the inside of the `dsl` block; namely, how to
describe the vocabulary.

We call the methods available inside the DSL "handlers."  How the DSL
handlers are configured determines how the DSL interacts with the
instance it is constructing.

#### Defining handlers with "on"

The `on` method is the basic building block of the DSL definition;
it's the generic tool used to describe what to do when handler is
called.  It's a lot like defining a method.

Let's support adding people to photo instances.

    # inside the DSL definition
    on :person do |photo, name|
      photo.add_person(name)
    end

This now lets us do the following when using the DSL:

  photo do
    person "Joe"
    person "Jack"
  end

We can support multiples, too:

    # inside the DSL definition
    on :people do |photo, *names|
      names.each do |name|
        photo.add_person(name)
      end
    end

 So we can do this, as well:

    photo do
      people "Joe", "Jack"
    end

#### Defining handlers with "use"

This configures the DSL to allow calls directly to methods on the
instance that's being constructed.

The `use` method works in two different modes:

1. Supporting an arbitrary length list of handler names; in this case
   the methods the DSL will call on the instance being constructed
   have exactly the names as the handlers provided:

       use :foo, :bar, :baz

2. Supporting a single hash argument that map names used in the DSL to
   the method names the DSL will call on the instance it's
   constructing:

       use :foo => :foo_implementation, :bar => :bar_implementation

We could easily refactor our `on`-based definition to add individual
people to a photo with `use`:

    use :person => :add_person

Note: `use` currently configures the DSL to pass on any arguments
directly to the methods on the instance it's constructing.  If you
need to check the number of arguments or do any type of data munging,
etc, use the more generic `on` instead.

#### Defining handlers with "set"

You use "set" to support calling attribute writers (methods ending in
"=").  Let's add support for setting the caption:

    # inside the DSL definition
    set :caption

Now it's as easy as:

    photo do
      caption "Joe and Jack fighting walruses"
    end

You can think of this as shorthand for:

    use :caption => :caption=

#### Documenting handlers with "desc"

This doesn't define DSL handlers, it documents them.  Use this just like
`desc` from Rake: simply put it before the `on`, `use`, or `set`
invocation.

    desc "Add a person to the photo. We prefer the format 'LAST_NAME,
          FIRST_NAME'"
    use :person => :add_person

Note: if you use `desc` immediately before an `on`, `use` or `set`
that creates configures multiple handlers, all will be given the same
description.  If you include `%s` in the string provided to `desc`,
the individual handler name will be inserted.

    desc "Configure the `%s' setting" 
    set :setting1, :setting2, :setting3 

#### Supporting manual instantiation with "construct"

The default behavior for the DSL entry point (eg, `photo`), when it is
called, is to pass on any additional arguments to the class' `new`
method (eg, `Photo.new`).

For example, you may notice that the `initialize` method of `Photo`
supports optional arguments to set the `caption` and `metadata` for
the photo.  Although we've configured the DSL to allow setting
`caption` manually (in the example for `set`, above), it can also be
set by the entry point:

    photo "this is a caption", :lens => '50mm' do
      # DSL definition here...
    end

While this is normally exactly what you want, you can also define
exactly how the instance is initialized by using `construct` in the
DSL definition.  This is especially helpful for
backwards-compatibility; when the implementation of the class
`initialize` method differs from how previous versions of the DSL are
used.

Use `construct` by giving it a block accepting the class (which will
automatically be passed into it) and the number of arguments the entry
point can accept. 

    # in the DSL definition
    construct do |klass, arg1, arg2, arg3|
      # construct an instance here...
    end

If we wanted to extend the entry point definition for `photo` to
disallow setting `metadata` and to support a quick definition of
people in the photo, we could do:

    # in the DSL definition
    construct do |klass, caption=nil, people=[]|
      instance = klass.new(caption)
      people.each { |person| instance.add_person(person) }
      instance # IMPORTANT
    end

IMPORTANT: The value resulting from calling the `construct` definition
block must *always* be a "kind of" the class `klass`.  Since you're
manually defining how instances are constructed, you are responsible for
ensuring an instance is returned from the block.

### Nesting DSLs

You many notice that, so far, the DSL is only one level deep: that is,
it only handles constructing and configuring one type of object (photos), and
does not extend to deeper levels of nesting.

Let's say we want to be able to configure `Person` instances as we
add people to a photo by descending into a deeper level of block syntax.
How would we do that?

Lacquer treats each class it uses to construct instances as separate
DSL hosts.  To support configuring people, we merely add a DSL to the
`Person` class; to the following class definition:

    class Person

      attr_accessor :age
      def initialize(name)
        @name = name
      end

    end

We could add:

    # inside the Person class
    include Lacquer::DSL

    dsl do
      desc "Set the person's age" 
      set :age
    end

Once this is done, we can easily add fully configured people to
photos:

    include Lacquer::DSL(:photo)
    # Note: I don't need to include Lacquer::DSL(:person)

    photo "School photo" do
      person "Sheila" do
        age 12
      end
      person "Bruce" do
        age 18
      end
    end
    
How does this work?  It's actually pretty simple.  After a DSL handler
is called (eg, `person`), Lacquer takes the return value and checks to
see if you've also provided a block.  If you have, it attempts to find
an appropriate DSL for the return value.

The method used to select a DSL is simple: if there is one DSL "name"
associated with the class and only one version, it will use that DSL.
If there's only one "name" but multiple versions, by default it will
use the newest (largest version number).  If there are multiple DSL
"names," it will, by default, select the newest version of the last
one defined.

* If it finds a DSL, it executes it with the block you've provided.
* If it doesn't find a DSL it, by default, simply ignores the block
  (to support methods that return `nil` or `false`).  You can make
  the behavior more stringent by using the `:stringent` option, described
  below.

### Common Options

All the DSL handler definition methods (`on`, `use`, and `set`) support a few
additional options that modify their behavior.

#### The "dsl" option

This affects the way Lacquer behaves when looking for a candidate DSL
for a nested DSL block; specifically, it describes a DSL name [and
optionally, version] constraint that is allowed to be used.

For instance, to force the `person` handler we defined with `use` above
to load the `1.0` version of the `person` DSL defined on `Person`:

    use {:person => :add_person}, :dsl => {:person => '1.0'}

Since the version constraint works with normal RubyGems-style
semantics, we can also do things like:

    use {:person => :add_person}, :dsl => {:person => '~> 1.0'}

Or, if we just want to give a friendly hint to the lookup and allow
any version:

    use {:person => :add_person}, :dsl => :person

If the `:dsl` option is set and no matching DSL is found, a
`Lacquer::MissingDSLError` will be raised.  If a DSL is found but not
appropriate for the value (ie, it does not inherit from the DSL's
target class), the block will be skipped -- unless the `:stringent`
option is used, as described below.

Default: `nil`

#### The "stringent" option

This affects the way Lacquer behaves when looking for a candidate DSL
for a nested DSL block; specifically, if set to `true`, it requires
that an appropriate DSL can be found for every return value-- a
`Lacquer::UnknownDSLError` is raised otherwise.

Default: `false`

#### The "required" option

This requires that the handler(s) created are invoked at least once
during the execution of the DSL block.  Think of this as a simple
`validates_presence_of`.

Validation of "correctness" isn't done.  To validate the  actual
arguments passed during invocation, define the handler using `on` and
check their values in the definition block -- or check them in the
underlying host class implementation.   

Default: `false`

#### The "desc" option

Just like the `desc` utility in the DSL definition, this provides a
description of the handler(s) created.

Default: `nil`

### Yield instead of Instance Eval

A nice side-effect of having the DSL separate from the underlying
class implementation is flexible use.

Remember the example above?

    photo "School photo" do
      person "Sheila" do
        age 12
      end
      person "Bruce" do
        age 18
      end
    end

If users prefer `yield`-based DSLs (or, if it just makes more sense
due to the context in which the DSL is used), they simply have to
accept a block argument.

For example, this will also work:

    photo "School photo" do |photo|
      photo.person "Sheila" do |person|
        person.age 12
      end
      photo.person "Bruce" do |person|
        person.age 18
      end
    end

Prefer this syntax yourself?  Document your DSL as such.

## Generating DSL documentation

_TODO_

## Note on Patches/Pull Requests to Lacquer
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
   bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2009 Bruce Williams. See LICENSE for details.
