# AccessStack
[![Build Status](https://travis-ci.org/fhsjaagshs/access_stack.png)](https://travis-ci.org/fhsjaagshs/access_stack) [![Code Climate](https://codeclimate.com/github/fhsjaagshs/access_stack.png)](https://codeclimate.com/github/fhsjaagshs/access_stack)

A general-purpose object "pool" for storing general objects. It can be a connection pool, cache, or even just a factory.

It takes the same parameters as ActiveRecord's connection pool and was built specifically for the gem `Mystic` (it's `Mystic`'s connection pool)

AccessStack is ***threadsafe***, obviously. It uses the `threadsafety` gem.

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
		:pool => 3, # size of pool (default 5)
		:checkout_timeout => 10, # Timeout in seconds for checking a connection out of the pool (default 5)
		:reaping_frequency => 5, # How often to run the reaper, in seconds (Default nil - don't run the reaper)
		:dead_connection_timeout # How long in seconds a connection is considered alive (default 5)
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

	s.create do
	  # do something
	end
	
	s.destroy do |inst|
	  # do something with inst
	end
	
	s.validate do |inst|
	  # return whether or not inst is valid
	end
	
Use an instance:

	res = s.with { |inst| inst.exec("SELECT * FROM users;") }
	# res is a PG::Result now, since that's what the block returned
	
Eager-load instances:
	
	s.fill! 5 # Add 5 objects to the stack
	s.fill! -1 # Fill stack to capacity-1
	s.fill! # Fill stack to capacity
	
Clear out instances:

	s.reap! # Validates each object using expires and validate
	s.clear! # Empties the stack
	s.empty? # Checks if the stack is empty
	s.available? # Whether or not the pool is full
	s.full? # Whether or not the stack is full

## Contributing

1. Fork it ( https://github.com/fhsjaagshs/access_stack/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
