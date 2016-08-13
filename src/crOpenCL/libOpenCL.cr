module CrOpenCL
  CL_SUCCESS = 0
  @[Link(framework: "OpenCL")]
  lib LibOpenCL
    # Investigate actual types in OpenCL
    alias Kernel = Void*
    alias PlatformID = UInt64
    alias DeviceID = UInt64
    alias Context = Void*
    alias CommandQueue = Void*
    alias Mem = Void*
    alias Program = Void*
    alias Event = Void*
    alias Sampler = Void*


    # Programs
    fun clCreateProgramWithSource(context : Context, count : UInt32, strings : UInt8**, lengths : UInt8*, errcode_ret : Int32*) : Program
    fun clBuildProgram(program : Program, num_devices : UInt32, device_list : DeviceID*, options : UInt8*, pfn_notify : (Program, Void* -> Void), user_data : Void*) : Int32
    # FIXME: param_name is actrually a cl_program_build_info enum
    fun clGetProgramBuildInfo(program : Program, device : DeviceID, param_name : Int64, param_value_size : UInt64, param_value : Void*, param_value_size_ret : UInt64*) : Int32
    fun clReleaseProgram(program : Program) : Int32

    # Contexts
    # FIXME: properties is actually a cl_context_properties enum *
    fun clCreateContext(properties : Int64*, num_devices : UInt32, devices : DeviceID*, pfn_notify : (UInt8*, Void*, UInt64, Void* -> Void), user_data : Void*, errcode_ret : Int32*) : Context
    fun clReleaseContext(context : Context) : Int32

    # Command Queues
    # FIXME: properties is actually a cl_command_queue_properties enum
    fun clCreateCommandQueue(context : Context, device : DeviceID, properties : Int64, errcode_ret : Int32*) : CommandQueue
    fun clReleaseCommandQueue(command_queue : CommandQueue) : Int32
    fun clFinish(command_queue : CommandQueue) : Int32

    # Kernels
    fun clCreateKernel(program : Program, kernel_name : UInt8*, errcode_ret : Int32*) : Kernel
    fun clReleaseKernel(kernel : Kernel) : Int32
    fun clSetKernelArg(kernel : Kernel, arg_index : Int32, arg_size : UInt64, arg_value : Void*) : Int32
    fun clEnqueueNDRangeKernel(command_queue : CommandQueue, kernel : Kernel, work_dim : UInt32, global_work_offset : UInt64*, global_work_size : UInt64*,
                               local_work_size : UInt64*, num_events_in_wait_list : Int32, event_wait_list : Event*, event : Event) : Int32
    # FIXME: param_name is actually a cl_kernel_work_group_info enum
    fun clGetKernelWorkGroupInfo(kernel : Kernel, device : DeviceID, param_name : Int64, param_value_size : UInt64, param_value : Void*, param_value_size_ret : UInt64*) : Int32

    # Memory
    # FIXME: flags is actually a cl_mem_flags enum
    fun clCreateBuffer(context : Context, flags : UInt64, size : UInt64, host_ptr : Void*, errcode_ret : Int32*) : Mem
    # FIXME: blocking_write is a cl_bool enum
    fun clEnqueueWriteBuffer(command_queue : CommandQueue, buffer : Mem, blocking_write : Int32, offset : UInt64, cb : UInt64, ptr : Void*,
                             num_events_in_wait_list : UInt32, event_wait_list : Event*, event : Event) : Int32
    # FIXME: blocking_read is a cl_bool enum
    fun clEnqueueReadBuffer(command_queue : CommandQueue, buffer : Mem, blocking_read : Int32, offset : UInt64, cb : UInt64, ptr : Void*,
                            num_events_in_wait_list : UInt32, event_wait_list : Event*, event : Event) : Int32
    fun clReleaseMemObject(memobj : Mem) : Int32

    # Events
    # FIXME: param_name is actually a cl_profiling_info enum
    fun clGetEventProfilingInfo(event : Event, param_name : Int64, param_value_size : UInt64, param_value : Void*, param_value_size_ret : UInt64*) : Int32

    # Device
    # FIXME: device_type is a cl_device_type enum
    fun clGetDeviceIDs(platform : PlatformID, device_type : Int64, num_entries : Int32, devices : DeviceID*, num_devices : UInt32*) : Int32
    # FIXME: param_name is a cl_device_info enum
    fun clGetDeviceInfo(device : DeviceID, param_name : UInt64, param_value_size : UInt64, param_value : Void*, param_value_size_ret : UInt64*) : Int32
  end
end
