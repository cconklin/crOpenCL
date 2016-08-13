require "./libOpenCL.cr"

module CrOpenCL
  class Program

    # TODO: Look up how to correctly subclass Exception in Crystal
    # TODO: Get error message from OpenCL
    # class BuildError < CLError
    # end

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

  end
end
