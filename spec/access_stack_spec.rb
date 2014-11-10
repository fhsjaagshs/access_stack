#!/usr/bin/env ruby

require "rspec"
require_relative "../lib/access_stack.rb"

CONCURRENCY = 5

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
    @s.fill!
    expect(res).to eq("THISFOOBAR")
    expect(@s.full?).to be_truthy
	end
	
	it "should work concurrently" do
		@s.fill!
		
    threads = []
    objs = []
    
    CONCURRENCY.times do |i|
      threads << Thread.new { @s.with { |obj| objs << obj } }
    end
    
    expect { threads.each(&:join) }.not_to raise_error
    expect(@s.count).to eql(CONCURRENCY)
    expect(objs.count).to eql(CONCURRENCY)
	end
	
  # TODO: This needs a lot of work
	#it "should be able to time out" do
  #  @s.checkout_timeout = 10 ** -1000
  #  puts @s.instance_variable_get "@checkout_timeout"
  #  expect { @s.with { |obj| obj + "FOOBAR" } }.to raise_error#(AccessStack::TimeoutError)
	#end
end