require "access_stack/version"
require "thread"
require "timeout"

class AccessStack
	attr_reader :count
	attr_accessor :expires, :size, :timeout, :create, :destroy, :validate

	TimeoutError = Class.new StandardError

	def initialize(params={})
		opts = Hash[params.map { |k,v| [k.to_sym, v] }]
		
		@timeout = opts[:timeout] || 5
		@size = opts[:size] || 5
		@expires = opts[:expires] || -1
		@expr_hash = {}
		@stack = []
		@count = 0
		@mutex = Mutex.new
		@create = opts[:create]
		@destroy = opts[:destroy]
		@validate = opts[:validate]
		@auto_purge = opts[:auto_purge] || false
	end

	def with(&block)
		begin
			obj = nil
		
			threadsafe do
				obj = @stack.pop
			end
		
			unless obj_valid? obj
				obj = nil
				@count -= 1
			end
		
			if @count < @size && obj.nil?
				@count += 1
				obj = create_obj
			end

			return block.call obj
		ensure
			threadsafe do
				@stack.push obj
			end
		end
	end
	
	def reap!
		return true if @count == 0
		threadsafe do
			@stack.each do |instance|
				unless obj_valid? instance
					@destroy.call instance
					@expr_hash.delete instance
					@stack.delete instance
					@count -= 1
					purging = false if @count == 0
				end
			end
		end
	end

	def empty!
		purging = false
		
		return if @count == 0
		threadsafe do
			@stack.each(&@destroy.method(:call))
			@expr_hash.clear
			@stack.clear
			@count = 0
		end
	end

	def fill
		create_objects @count
	end

	def create_objects(num=1)
		created_count = 0
	
		threadsafe do
			num.times do
				if @count < @size
					@stack.push create_obj
					@count += 1
					created_count += 1
					purging = true
				end
			end
		end
		
		created_count
	end

	def empty?
		@count == 0
	end

	private
	
	def create_obj
		obj = @create.call
		@expr_hash[obj] = Time.now
		obj
	end

	def obj_valid?(obj)
		block_valid = @vaildate.call obj rescue true
		expired = (@expires > 0 && @expr_hash[obj].to_f-Time.now.to_f > @expires)
		!expired && block_valid
	end

	def threadsafe(&block)
		
		if @threadsafe ||= false
			block.call
			return true
		end
		
		begin
		  Timeout::timeout @timeout do
		    @mutex.lock
		  end
			
			@threadsafe = true
		
			block.call
			@mutex.unlock
			@threadsafe = false
			return true
		rescue Timeout::Error
			raise TimeoutError, "Failed to obtain a lock fast enough."
		end
		false
	end
	
	def purging=(purging)
		@purging ||= false
		return if @purging == purging
		
		threadsafe do
			@purging = purging
		end
		
		if @purging
			Thread.new {
			  while @purging do
					sleep @expires
					reap!
			  end
			}
		end
	end
end
