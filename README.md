# AccessStack
[![Build Status](https://travis-ci.org/fhsjaagshs/access_stack.png)](https://travis-ci.org/fhsjaagshs/access_stack) [![Code Climate](https://codeclimate.com/github/fhsjaagshs/access_stack.png)](https://codeclimate.com/github/fhsjaagshs/access_stack)

A general-purpose object "pool" for storing general objects. It can be a connection pool, cache, or even just a factory.

## Notes

AccessStack is *very* threadsafe. It uses an internal stack to store the objects and any interaction with that is done with a `Mutex` lock in place.

AccessStack also implements most of the features present in ActiveRecord's connection pool, such as reaping, expiration, and timeout. It takes it a step farther by 

## Installation

Add this line to your application's Gemfile:

    gem 'access_stack'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install access_stack

## Usage

You can create a stack:

	require "access_stack"

	s = AccessStack.new(
	  :size => 10,
	  :timeout => 3, # how long to wait for access to the stack
	  :expires => 5, # how long an object lasts in the stack
	  :create => lambda {
	    PG.connect
	  },
	  :destroy => lambda { |instance|
	    instance.close
	  },
	  :validate => lamda { |instance|
	    instance.status == CONNECTION_OK
	  }
	)
	
Set a stack's blocks:

	s.create = lambda {
	  # Do something
	}
	
Use an instance:

	res = s.with { |inst| inst.exec("SELECT * FROM users;") }
	# res is a PG::Result now, since that's what the block returned
	
Eager-load instances:
	
	s.create_objects 5 # Create and add 5 objects to the stack
	s.fill # Fill the stack to capacity
	
Clear out instances:

	s.reap! # Validates each object using expires and validate
	s.empty! # Empties the stack
	s.empty? # Checks if the stack is empty


## TODO

1. Validate based upon methods on objects in the pool
2. Reap on an interval

## Contributing

1. Fork it ( https://github.com/fhsjaagshs/access_stack/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
