module SourceControl
  class AbstractRevision

    include Comparable

    def number
      raise NotImplementedError, "number() not implemented by #{self.class}"
    end

    # TODO: rename to author()
    def committed_by
      raise NotImplementedError, "author() not implemented by #{self.class}"
    end

    def time
      raise NotImplementedError, "time() not implemented by #{self.class}"
    end

    def <=>(other)
      raise NotImplementedError, "<=>() not implemented by #{self.class}"
    end

  end
end