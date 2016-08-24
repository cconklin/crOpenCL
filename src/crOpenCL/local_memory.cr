module CrOpenCL
  class LocalMemory(T)

    @elems : Int32

    property :dim

    def initialize(elems, *, @auto = false)
      @elems = elems.to_i32
      @dim = 1
    end

    def size
      @elems * sizeof(T)
    end

    def default(elems)
      if @auto
        @elems = (elems * dim).to_i32
      end
    end

    # Returns a local memory which will automatically size itself to the kernels local work group size
    def self.auto
      new(0, auto: true)
    end

  end
end
