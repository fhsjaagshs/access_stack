#!/usr/bin/env ruby

require "rspec"
require "access_stack"

def create_stack
	AccessStack.new(
		:size => 10,
		:timeout => 3,
		:create => lambda {
			"THIS"
		},
		:destroy => lambda { |instance|
			instance = nil
		},
		:validate => lambda { |instance|
			instance.is_a? String && instance.length > 0
		}
	)
end

describe AccessStack do
	
	it "should create objects" do
		stack = create_stack
		res = stack.with{ |inst| inst + "FOOBAR" } 
		stack.empty!
		res == "THISFOOBAR"
	end
	
	it "should work concurrently" do
		stack = create_stack
		stack.create_objects 1
		
		begin
			t = []
			
			t << Thread.new {
				stack.with{ |inst| inst + "ONE" }
			}
		
			t << Thread.new {
				stack.with{ |inst| inst + "TWO" }
			}
		
			t << Thread.new {
				stack.with{ |inst| inst + "Three" }
			}
			
			t.each(&:join)
		rescue StandardError => e
			puts e.message
			return false
		end
		
		stack.count == 3
	end
	
	it "should be able to time out" do
		stack = create_stack
		stack.timeout = 0.0000000000000001
		begin
			res = stack.with{ |inst| inst + "FOOBAR" } 
		rescue
			return false
		end
		true
	end

end