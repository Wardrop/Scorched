class Artist
  def self.[](*args)
    new
  end

  def method_missing(*args)
    true
  end
end

module Kernel
  def check_access(bool)
    bool
  end
end
