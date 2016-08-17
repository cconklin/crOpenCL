require "./libOpenCL.cr"

module CrOpenCL
  class Program

    # TODO: Look up how to correctly subclass Exception in Crystal
    # TODO: Get error message from OpenCL
    # class BuildError < CLError
    # end

    getter :context

    # Programs get run on a device.
    # Just return the device of the context the program was created under
    def device
      @context.device
    end

    def initialize(@context : Context, source : String)
      source_buf = source.to_unsafe
      @program = LibOpenCL.clCreateProgramWithSource(@context, 1.to_u32, pointerof(source_buf), nil, out create_program_err)
      raise CLError.new("clCreateProgramWithSource failed.") unless create_program_err == CL_SUCCESS

      # Using values from previous OpenCL programs as defaults
      # Probably want to expose these options at some point
      unless LibOpenCL.clBuildProgram(@program, 0.to_u32, nil, nil, nil, nil) == CL_SUCCESS
        raise CLError.new("clBuildProgram failed.")
      end
    end

    def to_unsafe
      @program
    end

    def finalize
      LibOpenCL.clReleaseProgram(@program)
    end

    # Call args to invoke kernel:
    # program.my_kernel queue, global_work_group_size, event, event_wait_list, kernel_args...
    # - queue (CommandQueue)
    # - global_work_group_size (> 0)
    # - event (Event | Nil)
    # - event_wait_list (Array(Event) | Nil)
    macro method_missing(call)
      %kernel = CrOpenCL::Kernel.new(self, {{call.name.stringify}})
      %kernel.set_arguments({{ *call.args[4..-1] }})
      %lwgs, %gwgs = %kernel.automatic_work_group_sizes({{ call.args[1] }}.to_i32)
      # Process work group size
      %kernel.enqueue({{ call.args[0] }}, local_work_size:  %lwgs.to_i32, global_work_size: %gwgs.to_i32, event: {{ call.args[2] }}, event_wait_list: ({{ call.args[3] }} || Array(Event).new))
    end

  end
end
