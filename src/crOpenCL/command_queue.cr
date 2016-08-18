require "./libOpenCL.cr"

module CrOpenCL

  class CommandQueue

    getter :device

    # Use actual OpenCL properties
    enum Properties : Int64
      Default = 0
      EnableProfiling = 2
    end

    @command_queue : LibOpenCL::CommandQueue

    # TODO: Add support for poperties
    def initialize(@context : Context, @device : Device, properties = Properties::Default)
      @command_queue = LibOpenCL.clCreateCommandQueue(@context, @device, properties, out err)
      raise CLError.new("clCreateCommandQueue failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def synchronize
      unless LibOpenCL.clFinish(@command_queue) == LibOpenCL::CL_SUCCESS
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
