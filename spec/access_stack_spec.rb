#!/usr/bin/env ruby

require "rspec"
require_relative "../lib/access_stack.rb"

describe AccessStack do
  
  before :each do
    @s = AccessStack.new(
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
	
	it "should create objects" do
		res = @s.with { |inst| inst + "FOOBAR" } 
		@s.empty!
		res == "THISFOOBAR"
	end
	
	it "should work concurrently" do
		@s.create_objects 1
		
		begin
			t = []
			
			t << Thread.new {
				@s.with { |inst| inst + "ONE" }
			}
		
			t << Thread.new {
				@s.with { |inst| inst + "TWO" }
			}
		
			t << Thread.new {
				@s.with { |inst| inst + "Three" }
			}
			
			t.each(&:join)
		rescue StandardError => e
			puts e.message
			return false
		end
		
		@s.count == 3
	end
	
	it "should be able to time out" do
		@s.timeout = 0.0000000000000001
		begin
			res = @s.with{ |inst| inst + "FOOBAR" } 
		rescue
			return false
		end
		true
	end

end