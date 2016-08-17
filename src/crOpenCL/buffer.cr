module CrOpenCL

  # TODO: Add support for other OpenCL mem flags
  enum Memory
    ReadOnly = 4
    WriteOnly = 2
    ReadWrite = 1

    def to_unsafe
      to_i64
    end
  end

  enum Transfer
    ToHost
    ToDevice
  end

  class Buffer(T)

    @length : UInt64
    @size : UInt64

    # If access allows reading, and the buffer has not been copied,
    # it will be copied directly prior to kernel launch on the kernel's command queue
    def initialize(@context : Context, @access : Memory, *, hostbuf : Array(T)? = nil, length = 0)
      # Tested this in the playground: even though kind holds the type of the array element
      # typeof is needed for this to work. It correctly gets the size of the type
      @length = (hostbuf.nil? ? length : hostbuf.size).to_u64
      raise CLError.new("Buffer cannot be zero size.") if @length == 0
      @hostbuf = hostbuf
      @size = @length * sizeof(T)
      # Create the buffer
      @buffer = LibOpenCL.clCreateBuffer(@context, @access, @size.to_u64, nil, out alloc_err)
      raise CLError.new("clCreateBuffer failed.") unless alloc_err == CL_SUCCESS
    end

    def self.enqueue_copy(queue : CommandQueue, hostbuf : Slice(T), devbuf : Buffer, length : UInt64, direction : Transfer, *, blocking = false, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      blocking = blocking ? 1 : 0
      event_wait_list ||= Array(Event).new
      ewl_size = event_wait_list.size
      # If there is an event wait list, make it into the right type
      # Otherwise, it should be NULL (as per OpenCL)
      ewl = ewl_size > 0 ? event_wait_list.map(&.to_unsafe_value).to_unsafe : Pointer(Pointer(Void)).null
      if direction == Transfer::ToHost
        err = LibOpenCL.clEnqueueReadBuffer(queue, devbuf, blocking.to_i32, 0, length * sizeof(T), hostbuf, ewl_size, ewl, event)
        raise CLError.new("clEnqueueWriteBuffer failed.") unless err == CL_SUCCESS
      else
        err = LibOpenCL.clEnqueueWriteBuffer(queue, devbuf, blocking.to_i32, 0, length * sizeof(T), hostbuf, ewl_size, ewl, event)
        raise CLError.new("clEnqueueWriteBuffer failed.") unless err == CL_SUCCESS
      end
    end

    def set(queue : CommandQueue, *, hostbuf : Array(T), blocking = false, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      slice = Slice(T).new(hostbuf.to_unsafe, hostbuf.size)
      Buffer(T).enqueue_copy(queue, slice, self, hostbuf.size.to_u64, Transfer::ToDevice, blocking: blocking, event: event, event_wait_list: event_wait_list)
    end

    def set(queue : CommandQueue, *, blocking = false, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      raise CLError.new("No host buffer to copy.") if @hostbuf.nil?
      slice = Slice(T).new(@hostbuf.as(Array(T)).to_unsafe, @hostbuf.as(Array(T)).size)
      Buffer(T).enqueue_copy(queue, slice, self, slice.size.to_u64, Transfer::ToDevice, blocking: blocking, event: event, event_wait_list: event_wait_list)
    end

    def get(queue : CommandQueue, hostbuf : Array(T), *, blocking : Bool, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      slice = Slice(T).new(hostbuf.to_unsafe, hostbuf.size)
      Buffer(T).enqueue_copy(queue, slice, self, hostbuf.size.to_u64, Transfer::ToHost, blocking: blocking, event: event, event_wait_list: event_wait_list)
      nil
    end

    def get(queue : CommandQueue, hostbuf : Array(T), *, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      get(queue, hostbuf, blocking: true, event: event, event_wait_list: event_wait_list)
      return hostbuf
    end

    def get(queue : CommandQueue, *, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      if @hostbuf.nil?
        # Doing this instead of creating the array directly gives the array the correct size
        # i.e. the array knows it has @length elements
        buf = Slice(T).new(@length).to_a
        get(queue, buf, event: event, event_wait_list: event_wait_list)
      else
        get(queue, @hostbuf.as(Array(T)), event: event, event_wait_list: event_wait_list)
      end
    end

    def to_unsafe
      @buffer
    end

    def finalize
      LibOpenCL.clReleaseMemObject(@buffer)
    end
  end
end
