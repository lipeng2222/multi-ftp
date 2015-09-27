class File
  def self.append(to_fn, from_fn, append_size = 0)
    return unless File.file?(from_fn)
    to_f = File.new(to_fn, "a")
    from_f = File.new(from_fn, "r")
    to_f.binmode
    from_f.binmode
    
    count = to_f.write(from_f.read(append_size))
    
    to_f.close
    from_f.close
    warn "syswrite size : #{count}" if $DEBUG
  end
end
