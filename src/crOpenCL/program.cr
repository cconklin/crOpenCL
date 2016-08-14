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

    macro method_missing(call)
      %kernel = CrOpenCL::Kernel.new(self, {{call.name.stringify}})
      %kernel.set_arguments({{ *call.args[2..-1] }})
      %gwgs = {{ call.args[1] }}
      %lwgs = %kernel.get_work_group_info(KernelParams::WorkGroupSize)
      # Process work group size
      %kernel.enqueue({{ call.args[0] }}, local_work_size: 3, global_work_size: {{ call.args[1] }})
    end

  end
end
