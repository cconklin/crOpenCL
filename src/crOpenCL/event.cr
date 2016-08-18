require "./libOpenCL.cr"

module CrOpenCL
  class Event

    getter :name

    enum ExecutionStatus
      Queued
      Submitted
      Running
      Complete
      Error
    end

    def initialize(@name : String)
      @event = uninitialized LibOpenCL::Event
    end

    def profiling_info
      infos = {queued: LibOpenCL::CL_PROFILING_COMMAND_QUEUED,
               submit: LibOpenCL::CL_PROFILING_COMMAND_SUBMIT,
               start: LibOpenCL::CL_PROFILING_COMMAND_START,
               finish: LibOpenCL::CL_PROFILING_COMMAND_END}
      data = {
        :queued => 0u64,
        :submit => 0u64,
        :start  => 0u64,
        :finish => 0u64
      }
      val = uninitialized UInt64
      infos.each do |name, cl_param|
        stat = LibOpenCL.clGetEventProfilingInfo(@event, cl_param, sizeof(UInt64), pointerof(val), nil)
        if stat == LibOpenCL::CL_PROFILING_INFO_NOT_AVAILABLE
          raise ProfilingNotAvailable.new("Profiling info is not available for event #{self}")
        elsif stat == LibOpenCL::CL_INVALID_EVENT
          raise Invalid.new("#{self} is not a valid event")
        elsif stat != LibOpenCL::CL_SUCCESS
          raise CLError.new("clGetEventProfilingInfo failed.")
        end
        data[name] = val
      end
      return data
    end

    def execution_status
      val = uninitialized Int32
      stat = LibOpenCL.clGetEventInfo(@event, LibOpenCL::CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(Int32), pointerof(val), nil)
      raise CLError.new("clGetEventProfilingInfo failed.") if stat != LibOpenCL::CL_SUCCESS
      case val
      when LibOpenCL::CL_QUEUED
        ExecutionStatus::Queued
      when LibOpenCL::CL_SUBMITTED
        ExecutionStatus::Submitted
      when LibOpenCL::CL_RUNNING
        ExecutionStatus::Running
      when LibOpenCL::CL_COMPLETE
        ExecutionStatus::Complete
      else
        ExecutionStatus::Error
      end
    end

    def to_unsafe
      pointerof(@event)
    end

    def to_unsafe_value
      @event
    end

    def finalize
      LibOpenCL.clReleaseEvent(@event)
    end

  end
end
