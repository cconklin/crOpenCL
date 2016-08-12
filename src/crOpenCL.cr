require "./crOpenCL/*"

module CrOpenCL
  class CLError < Exception
  end
end

puts CrOpenCL::Device.all
