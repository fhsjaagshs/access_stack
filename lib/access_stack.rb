#!/usr/bin/env ruby

require "threadsafety"
require "timeout"

class AccessStack
  include Threadsafety # makes setters threadsafe + adds threadsafe method
	attr_reader :count,
              :create,
              :destroy,
              :validate
  attr_accessor :pool,
                :checkout_timeout,
                :reaping_frequency,
                :dead_connection_timeout

	TimeoutError = Class.new StandardError
  DestructorError = Class.new StandardError
  CreatorError = Class.new StandardError
  
=begin
  pool - size of pool (default 5)
  checkout_timeout - number of seconds to wait when getting a connection from the pool
  reaping_frequency - number of seconds to run the reaper (nil means don't run the reaper)
  dead_connection_timeout - number of seconds after which the reaper will consider a connection dead. (default 5 seconds)
=end

	def initialize params={}
    opts = params.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
    
    @pool = opts[:pool] || 5
    @checkout_timeout = opts[:checkout_timeout] || 5
    @reaping_frequency = opts[:reaping_frequency] || nil
    @dead_connection_timeout = opts[:dead_connection_timeout] || 5
    
    @purging = false
		start_purging! unless @reaping_requency.nil?
    
		@expr_hash = {}
		@stack = []
		@count = 0
		@create = opts[:create]
		@destroy = opts[:destroy]
		@validate = opts[:validate]
	end
  
  # threadsafe setters
  def create &block; threadsafe { @create = block }; end
  def destroy &block; threadsafe { @destroy = block }; end
  def validate &block; threadsafe { @validate = block }; end
  
	def empty?; @count.zero?; end
  def full?; @count == @pool; end
  def available?; !(full? && @stack.empty?); end
  
	def with &block
    raise CreatorError, "No :create block provided." if @create.nil?
    raise DestructorError, "No :destroy block provided." if @destroy.nil?
		begin
      obj = threadsafe { Timeout.timeout(@checkout_timeout, TimeoutError) { @stack.pop } }
      
      if !_obj_valid?(obj) && !obj.nil?
        @destroy.call obj
        @expr_hash.delete obj
        @count -= 1
        obj = nil
      end
      
      obj = @create.call if obj.nil?
      @expr_hash[obj] = Time.now

			block.call obj
		ensure
      threadsafe { @stack.push obj }
      fill! if empty?
		end
	end
	
	def reap!
    raise DestructorError, "No :destroy block provided." if @destroy.nil?
		return if empty?
		threadsafe do
			@stack.each do |obj|
				unless _obj_valid? obj
					@destroy.call obj
					@expr_hash.delete obj
					@stack.delete obj
					@count -= 1
				end
			end
		end
	end

	def clear!
		return if @count.zero?
		threadsafe do
			@stack.each(&@destroy.method(:call))
			@expr_hash.clear
			@stack.clear
			@count = 0
		end
	end

	def fill! num=@pool-@count
    raise CreatorError, "No :create block provided." if @create.nil?
    return 0 if full?
    return 0 if num.zero?

		threadsafe do
      num.times do
        obj = @create.call
        @expr_hash[obj] = Time.now
        @stack.push obj
      end
      @count += num
		end
    
    start_purging!
		
		num
	end
  
  def start_purging! f=-1
    threadsafe { @reaping_frequency = f unless f == -1 }
    return if @purging
    threadsafe { @purging = true }
		Thread.new do
		  while !@reaping_requency.nil? && !@reaping_requency.zero? && @purging && !empty? do
				sleep @reaping_frequency
				reap!
		  end
    end
  end

  def stop_purging!
    return unless @purging
    threadsafe { @purging = false }
  end

	private

	def _obj_valid? obj
    return false if obj.nil?
		block_valid = true#@validate.nil? ? true : @vaildate.call(obj)
		expired = (@dead_connection_timeout > 0 && (@expr_hash[obj]-Time.now).to_f > @dead_connection_timeout)
		!expired && block_valid
	end
end
