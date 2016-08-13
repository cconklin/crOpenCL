require "./libOpenCL.cr"

module CrOpenCL

  class CommandQueue

    # Use actual OpenCL properties
    enum Properties
      Default = 0

      def to_unsafe
        to_i64
      end
    end

    @command_queue : LibOpenCL::CommandQueue

    # TODO: Add support for poperties
    def initialize(@context : Context, @device : Device)
      @command_queue = LibOpenCL.clCreateCommandQueue(@context, @device, Properties::Default, out err)
      raise CLError.new("clCreateCommandQueue failed.") unless err == CL_SUCCESS
    end

    def synchronize
      unless LibOpenCL.clFinish(@command_queue) == CL_SUCCESS
        raise CLError.new("clFinish failed.")
      end
    end

    def to_unsafe
      @command_queue
    end

    def finalize
      LibOpenCL.clReleaseCommandQueue(@command_queue)
    end
  end
end
