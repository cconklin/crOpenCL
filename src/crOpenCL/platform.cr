module CrOpenCL
  enum PlatformParameters
    Profile = 2304
    Version = 2305
    Name = 2306
    Vendor = 2307
    Extensions = 2308
  end

  class Platform

    getter :profile, :version, :name, :vendor, :extensions

    @id : LibOpenCL::PlatformID
    @profile = ""
    @version = ""
    @name = ""
    @vendor = ""
    @extensions = [] of String

    def initialize(id : UInt64)
      @id = id.as(LibOpenCL::PlatformID)
      @profile = get_info_string(PlatformParameters::Profile)
      @version = get_info_string(PlatformParameters::Version)
      @name = get_info_string(PlatformParameters::Name)
      @vendor = get_info_string(PlatformParameters::Vendor)
      @extensions = get_info_string(PlatformParameters::Extensions).split(" ")
    end

    private def get_info_string(param : PlatformParameters)
      # Get the size of the C string to be returned from OpenCL
      stat = LibOpenCL.clGetPlatformInfo(@id, param, 0, nil, out size)
      raise CLError.new("clGetPlatformInfo failed.") unless stat == LibOpenCL::CL_SUCCESS

      # Allocate a buffer large enough to hold the string
      str = Slice(UInt8).new(size)
      # Get the value from OpenCL
      stat = LibOpenCL.clGetPlatformInfo(@id, param, size, str, nil)
      raise CLError.new("clGetPlatformInfo failed.") unless stat == LibOpenCL::CL_SUCCESS
      # C strings are null terminated, Crystal's are not: remove the last character (null terminator)
      # Sometimes the string from OpenCL ends in a space. Strip it away
      return String.new(str[0, size-1]).strip
    end

    def to_unsafe
      @id
    end

    def self.each
      err = LibOpenCL.clGetPlatformIDs(0, nil, out num_platforms)
      raise CLError.new("clGetPlatformIDs failed.") unless err == LibOpenCL::CL_SUCCESS

      platform_ids = Slice(UInt64).new(num_platforms)

      err = LibOpenCL.clGetPlatformIDs(num_platforms, platform_ids, nil)
      raise CLError.new("clGetPlatformIDs failed.") unless err == LibOpenCL::CL_SUCCESS

      platform_ids.each {|id| yield new(id) }
    end

    def self.all
      platforms = [] of Platform
      each do |platform|
        platforms << platform
      end
      platforms
    end

  end
end
