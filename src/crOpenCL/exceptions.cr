module CrOpenCL
  class CLError < Exception
  end
  class Invalid < CLError
  end
  class ProfilingNotAvailable < CLError
  end
  class BuildError < CLError
  end
end
