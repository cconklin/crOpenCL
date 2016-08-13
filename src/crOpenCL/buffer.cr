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
    def initialize(@context : Context, @access : Memory, *, hostbuf : Array(T), length : UInt64 = 0)
      # Tested this in the playground: even though kind holds the type of the array element
      # typeof is needed for this to work. It correctly gets the size of the type
      @length = (hostbuf.nil? ? length : hostbuf.size).to_u64
      @hostbuf = hostbuf
      @size = @length * sizeof(T)
      # Create the buffer
      @buffer = LibOpenCL.clCreateBuffer(@context, @access, @size.to_u64, nil, out alloc_err)
      raise CLError.new("clCreateBuffer failed.") unless alloc_err == CL_SUCCESS
    end

    def enqueue_copy(queue : CommandQueue, direction : Transfer, *, blocking : (Bool | Nil) = nil)
      if direction == Transfer::ToHost
        blocking ||= true
        blocking = blocking ? 1 : 0
        # If there is a host_buffer, use it instead
        dest_ary = @hostbuf.nil? ? Array(T).new(@length) : @hostbuf
        err = LibOpenCL.clEnqueueReadBuffer(queue, @buffer, blocking.to_i32, 0, @size, dest_ary, 0 , nil, nil)
        raise CLError.new("clEnqueueWriteBuffer failed.") unless err == CL_SUCCESS
        return dest_ary
      else
        blocking = blocking ? 1 : 0
        raise CLError.new("No host buffer to copy.") if @hostbuf.nil?
        err = LibOpenCL.clEnqueueWriteBuffer(queue, @buffer, blocking.to_i32, 0, @size, @hostbuf, 0 , nil, nil)
        raise CLError.new("clEnqueueWriteBuffer failed.") unless err == CL_SUCCESS
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
