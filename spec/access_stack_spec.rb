#!/usr/bin/env ruby

require "rspec"
require_relative "../lib/access_stack.rb"

describe AccessStack do
  before :each do
    @s = AccessStack.new
    @s.create { "THIS" }
    @s.destroy { |obj| obj = nil }
    @s.validate { |obj| obj.is_a? String && obj.length > 0 }
  end
	
	it "should create objects" do
		res = @s.with { |inst| inst + "FOOBAR" } 
		@s.clear!
		res == "THISFOOBAR"
	end
	
	it "should work concurrently" do
		@s.fill! 1
		
		begin
     # values = []
			t = []
			t << Thread.new { @s.with { |inst| inst + "ONE" } }
			t << Thread.new { @s.with { |inst| inst + "TWO" } }
			t << Thread.new { @s.with { |inst| inst + "THREE" } }
			t.each(&:join)
    #  @s.count == 3# && values == ["THISONE","THISTWO","THISTHREE"]
		rescue StandardError => e
			puts e.message
			false
		end
		
		@s.count == 3
	end
	
	it "should be able to time out" do
		@s.dead_connection_timeout = 0.0000000000000001
		@s.with { |inst| inst + "FOOBAR" } != nil rescue AccessStack::TimeoutError false
	end
end