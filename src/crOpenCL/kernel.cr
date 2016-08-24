require "./libOpenCL.cr"

module CrOpenCL

  enum KernelParams : Int64
    WorkGroupSize = 4528
  end

  class Kernel

    def initialize(@program : Program, @name : String)
      @kernel = LibOpenCL.clCreateKernel(@program, @name, out err)
      raise CLError.new("clCreateKernel failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def set_argument(index : Int32, mem : LocalMemory)
      mem.default(local_work_group_size)
      err = LibOpenCL.clSetKernelArg(@kernel, index, mem.size, nil)
      raise CLError.new("clSetKernelArg failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def set_argument(index : Int32, value)
      val = value.responds_to?(:to_unsafe) ? value.to_unsafe : value
      err = LibOpenCL.clSetKernelArg(@kernel, index, sizeof(typeof(value)), pointerof(val))
      raise CLError.new("clSetKernelArg failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def to_unsafe
      @kernel
    end

    def finalize
      LibOpenCL.clReleaseKernel(@kernel)
    end

    def enqueue(queue : CommandQueue, *, global_work_size : Tuple, local_work_size : Tuple?, event : Event? = nil, event_wait_list : Array(Event)? = nil)
      gws = global_work_size.to_a.map(&.to_u64)
      dim = gws.size
      unless local_work_size.nil?
        lws = local_work_size.to_a.map(&.to_u64)
        raise ArgumentError.new("Local work size dimension (#{lws.size}) must equal global work size dimension (#{gws.size})") unless lws.size == gws.size
      end
      # Doing this rather than make the default argument this to allow for passing nil explicitly (as is done in actual OpenCL)
      event_wait_list ||= Array(Event).new
      ewl_size = event_wait_list.size
      ewl = ewl_size > 0 ? event_wait_list.map(&.to_unsafe_value).to_unsafe : Pointer(Pointer(Void)).null
      err = LibOpenCL.clEnqueueNDRangeKernel(queue, @kernel, dim, nil, gws, lws, ewl_size, ewl, event)
      raise CLError.new("clEnqueueNDRangeKernel failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def get_work_group_info(param_name : KernelParams)
      # Note: Some other params may have a size different that that of UInt64
      value = uninitialized UInt64
      err = LibOpenCL.clGetKernelWorkGroupInfo(@kernel, @program.device, param_name, sizeof(typeof(value)), pointerof(value), nil)
      raise CLError.new("clGetKernelWorkGroupInfo failed.") unless err == LibOpenCL::CL_SUCCESS
      return value
    end

    def local_work_group_size
      get_work_group_info(KernelParams::WorkGroupSize)
    end

    # method_missing seems to be the only way to get a macro as a method with AST arguments
    macro method_missing(call)
      {% if call.name == "set_arguments" %}
        {% for arg, index in call.args %}
          set_argument({{index}}, {{arg}})
        {% end %}
      {% else %}
        # TODO Find a way to get the source line and file in the error message
        {{ raise "Invalid kernel method: " + call.name.stringify }}
      {% end %}
    end
  end
end
