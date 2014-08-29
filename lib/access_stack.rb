require "access_stack/version"
require "thread"

class AccessStack
	attr_reader :count
	attr_accessor :expires, :size, :timeout, :create, :destroy, :validate

	TimeoutError = Class.new StandardError
  DestructorError = Class.new StandardError
  CreatorError = Class.new StandardError

	def initialize params={}
    opts = params.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
		
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

	def with &block
		begin
      obj = nil
			threadsafe { obj = @stack.pop }

			unless obj_valid? obj
				obj = nil
				@count -= 1
			end
		
			if @count < @size && obj.nil?
				@count += 1
				obj = create_obj
			end

			block.call obj
		ensure
			threadsafe { @stack.push obj }
		end
	end
	
	def reap!
		return if @count == 0
    raise DestructorError, "No :destroy block provided." if @destroy.nil?
		threadsafe do
			@stack.each do |inst|
				unless obj_valid? inst
					@destroy.call inst
					@expr_hash.delete inst
					@stack.delete inst
					@count -= 1
					purging = false if @count == 0
				end
			end
		end
	end

	def empty!
		purging = false
		
		return if @count.zero?
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

	def create_objects num=1
		create_count = [@size-@count,num].min
    return create_count if create_count.zero?
    
		threadsafe do
			create_count.times { @stack.push create_obj }
      purging = true
      @count += create_count
		end
		
		create_count
	end

	def empty?
		@count.zero?
	end

	private
	
	def create_obj
    raise CreatorError, "No :create block provided." if @destroy.nil?
		obj = @create.call
		@expr_hash[obj] = Time.now
		obj
	end

	def obj_valid? obj
		block_valid = @vaildate.call obj rescue true
		expired = (@expires > 0 && @expr_hash[obj].to_f-Time.now.to_f > @expires)
		!expired && block_valid
	end

	def threadsafe &block
    if @mutex.locked?
      block.call
      return
    end
    
    begin
      t = Thread.current
      s = Thread.start do
        sleep @timeout
        t.raise TimeoutError, "Failed to obtain a lock fast enough."
      end
      
      @mutex.lock
    ensure
      if s
        s.kill
        s.join
      end
    end
    
		block.call
		@mutex.unlock
	end
	
	def purging= purging
		@purging ||= false
		return if @purging == purging
		
		threadsafe { @purging = purging }

		if @purging
			Thread.new do
			  while @purging do
					sleep @expires
					reap!
			  end
      end
		end
	end
end
