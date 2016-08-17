require "./libOpenCL.cr"

module CrOpenCL

  enum KernelParams
    WorkGroupSize = 4528

    def to_unsafe
      to_i64
    end
  end

  class Kernel

    def initialize(@program : Program, @name : String)
      @kernel = LibOpenCL.clCreateKernel(@program, @name, out err)
      raise CLError.new("clCreateKernel failed.") unless err == CL_SUCCESS
    end

    def set_argument(index : Int32, value)
      val = value.responds_to?(:to_unsafe) ? value.to_unsafe : value
      err = LibOpenCL.clSetKernelArg(@kernel, index, sizeof(typeof(value)), pointerof(val))
      raise CLError.new("clSetKernelArg failed.") unless err == CL_SUCCESS
    end

    def to_unsafe
      @kernel
    end

    def finalize
      LibOpenCL.clReleaseKernel(@kernel)
    end

    def enqueue(queue : CommandQueue, *, global_work_size : Int32, local_work_size : Int32, event : (Event | Nil) = nil, event_wait_list : (Array(Event) | Nil) = nil)
      lws = local_work_size.to_u64
      gws = global_work_size.to_u64
      # Doing this rather than make the default argument this to allow for passing nil explicitly (as is done in actual OpenCL)
      event_wait_list ||= Array(Event).new
      ewl_size = event_wait_list.size
      ewl = ewl_size > 0 ? event_wait_list.map(&.to_unsafe_value).to_unsafe : Pointer(Pointer(Void)).null
      err = LibOpenCL.clEnqueueNDRangeKernel(queue, @kernel, 1, nil, pointerof(gws), pointerof(lws), ewl_size, ewl, event)
      raise CLError.new("clEnqueueNDRangeKernel failed.") unless err == CL_SUCCESS
    end

    def get_work_group_info(param_name : KernelParams)
      # Note: Some other params may have a size different that that of UInt64
      value = uninitialized UInt64
      err = LibOpenCL.clGetKernelWorkGroupInfo(@kernel, @program.device, param_name, sizeof(typeof(value)), pointerof(value), nil)
      raise CLError.new("clGetKernelWorkGroupInfo failed.") unless err == CL_SUCCESS
      return value
    end

    def automatic_work_group_sizes(requested_gwgs : Int32)
      max_lwgs = get_work_group_info(KernelParams::WorkGroupSize)
      if requested_gwgs % max_lwgs == 0
        # they divide each other -- good to go
        return max_lwgs, requested_gwgs
      else
        # Currently making the global work group size larger to be divisible
        # should the local work group size be made smaller instead? -- easier on programmer but lower performance
        gwgs = (requested_gwgs / max_lwgs + 1) * max_lwgs
        return max_lwgs, gwgs
      end
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
