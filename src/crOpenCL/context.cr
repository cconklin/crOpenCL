require "./libOpenCL"
require "./device"

module CrOpenCL

  class Context

    getter :device

    # Create a new context on device
    # Currently only supports one device
    # Currently no callbacks
    def initialize(@device : Device)
      device_id = @device.to_unsafe
      # clCreateContext expects a C-array (pointer) to devices
      # since we currently only support 1 device per context, just ge a pointer to the device id
      @context = LibOpenCL.clCreateContext(nil, 1, pointerof(device_id), nil, nil, out err)
      raise CLError.new("clCreateContext failed.") unless err == LibOpenCL::CL_SUCCESS
    end

    def to_unsafe
      @context
    end

    def finalize
      LibOpenCL.clReleaseContext(@context)
    end
  end

  # Prompt the user to select a device and create a context from that
  def self.create_some_context
    platforms = Platform.all
    if platforms.size > 1
      puts "Choose Platform:"
      platforms.each_with_index do |platform, index|
        puts "[#{index}] #{platform.name}"
      end
      print "Choice: "
      index = (gets || 0).to_i
      platform = platforms.size > index ? platforms[index] : platforms[0]
    elsif platforms.size == 1
      platform = platforms[0]
      puts "Using Platform: #{platform.name}"
    else
      raise "No OpenCL Platforms"
    end
    devices = Device.all platform
    if devices.size > 1
      puts "Choose Device:"
      devices.each_with_index do |device, index|
        puts "[#{index}] #{device.name}"
      end
      print "Choice: "
      index = (gets || 0).to_i
      # The PyOpenCL behavior when the user enters a bogus device is to use device 0
      # That seems like a sane choice
      device = devices.size > index ? devices[index] : devices[0]
    elsif devices.size == 1
      device = devices[0]
      puts "Using Device: #{device.name}"
    else
      raise "No OpenCL Devices"
    end
    Context.new(device)
  end

end
