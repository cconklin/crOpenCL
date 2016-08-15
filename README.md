# crOpenCL [![Build Status](https://travis-ci.org/cconklin/crOpenCL.svg?branch=master)](https://travis-ci.org/cconklin/crOpenCL)

OpenCL Bindings fo Crystal

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  crOpenCL:
    github: cconklin/crOpenCL
```

Currently only supports Mac OS


## Usage


```crystal
require "crOpenCL"
```

## Example

```crystal
require "crOpenCL"
require "random"

# Generate random inputs
total = 10_000_000
in1 = Array.new(total) {|x| Random.rand(-10.0...10.0).to_f32 }
in2 = Array.new(total) {|x| Random.rand(-10.0...10.0).to_f32 }

# Prompts the user to choose a device
context = CrOpenCL.create_some_context
queue = CrOpenCL::CommandQueue.new context, context.device, CrOpenCL::CommandQueue::Properties::EnableProfiling

# Compile our OpenCL kernel
program = CrOpenCL::Program.new context, <<-PROGRAM

__kernel void sum(__global float * result, __global float * in1, __global float * in2, const int len)
{
  int idx = get_global_id(0);
  if (idx < len)
  {
    result[idx] = in1[idx] + in2[idx];
  }
}

PROGRAM

xin1 = CrOpenCL::Event.new "Transfer 1 In"
xin2 = CrOpenCL::Event.new "Transfer 2 In"
kern = CrOpenCL::Event.new "Kernel"
xout = CrOpenCL::Event.new "Transfer Out"

# Transfer inputs to device
d_in1 = CrOpenCL::Buffer.new(context, CrOpenCL::Memory::ReadOnly, hostbuf: in1)
d_in2 = CrOpenCL::Buffer.new(context, CrOpenCL::Memory::ReadOnly, hostbuf: in2)
d_in1.set queue, event: xin1
d_in2.set queue, event: xin2
# Allocate output buffer
d_result = CrOpenCL::Buffer(Float32).new(context, CrOpenCL::Memory::WriteOnly, length: total)

# Run program
program.sum(queue, total, kern, d_result, d_in1, d_in2, total)

# Get result back to host
result = d_result.get queue, event: xout

# Look at the runtimes of transfer and kernel
events = { xin1, xin2, kern, xout }

events.each do |event|
  info = event.profiling_info
  puts "#{event.name} (#{event.execution_status}): #{(info[:finish] - info[:start]) / 1000} µs"
end
```

## Issues

1. Can't develop tests to verify the interaction with the C libs, as mocks don't support it yet.

## Contributing

1. Fork it ( https://github.com/[your-github-name]/crOpenCL/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [cconklin](https://github.com/cconklin) Chase Conklin - creator, maintainer
