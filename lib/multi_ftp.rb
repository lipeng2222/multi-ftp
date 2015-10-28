# encoding: UTF-8
require 'net/ftp'
require 'thread'
require_relative 'file_extend'

# == Major Methods
#
# The following are the methods most likely to be useful to users:
# - binary(default true)
# - passive(default true)
#
# The following are the methods most likely to be useful to users:
# - #sendcmd
# - #rest_support?
# - #get
# - #put
# - #chdir
# - #nlst
# - #size
# - #rename
# - #delete
#
class MultiFTP < Net::FTP
  attr_reader :host, :port, :user , :threads
  
  def initialize(host = nil, port = nil, user = nil, passwd = nil)
    super()  
    @host = host
    @port = port || 21
    @user = user
    @passwd = passwd
    @threads = 5
    @resume = true       # must be true, so it support resume or multi-thread
    @binary = true
    @passive = true
    if host
      connect(@host, @port)
      if user 
        login(@user, @passwd);end
    end
  end
  
  # 返回350成功代码，说明支持rest，就可实现多线程下载
  def rest_support?
    unless @logged_in
      connect(@host, @port)
      login(@user, @passwd)
    end
    
    resp=sendcmd "REST 0"
    resp[/^350 /] ? true : false
  end
  
  [:get, :put].each do |method|
    define_method("multi_#{method}".to_sym) do |remotefile, localfile = File.basename(remotefile),
                                        blocksize = DEFAULT_BLOCKSIZE, &block|
      if @binary
        send "multi_#{method}_binary".to_sym, remotefile, localfile, blocksize, &block 
      else
        send "#{method}textfile".to_sym, remotefile, localfile, &block
      end 
    end # define_method block      
      
    define_method(method) do |remotefile, localfile = File.basename(remotefile),
                        blocksize = DEFAULT_BLOCKSIZE, &block|
      if @resume && rest_support?                                
        send "multi_#{method}".to_sym, remotefile, localfile, blocksize, &block 
      else
        warn "warn:服务器不支持断点续传和多线程！"
        super(remotefile, localfile, blocksize, &block)
      end
    end # define_method block
  end # each block
  
  private  
  def multi_get_binary(remotefile, localfile = File.basename(remotefile),
                                        blocksize = DEFAULT_BLOCKSIZE, &block)
    total_size = size(remotefile)
    part_size = total_size / (@threads.to_i - 1) rescue total_size
    threads = []
    
    @threads.times do |t|
      ftp = Net::FTP.new
      ftp.connect(@host, @port)
      ftp.login(@user, @passwd)
      ftp.resume = true

      thread = Thread.new do
        part_file = localfile + ".Part#{t + 1}"
        if File.exists?(part_file)
          size = File.size(part_file)
          rest_offset = t * part_size + size
          f = open(part_file, "a")
        else
          rest_offset = t * part_size
          f = open(part_file, "w")
        end
        
        begin
          f.binmode
          count = 0

          ftp.retrbinary("RETR " + remotefile.to_s, blocksize, rest_offset) do |data|
            f.write(data)
            count += data.size
            yield(data) if block_given?
            break if count >= part_size
          end
        ensure
          ftp.close
        end        
      end # thread block
      threads << thread
    end # times block
    threads.each { |t| t.join }
    puts "download ok!" if $DEBUG
    conflate_part_files(localfile, part_size)
  end # end def
  
  def multi_thread_dwn_ok?(threads)
    threads.each { |t| return false if t.alive? }
    true
  end

  def conflate_part_files(filename, size)
    all_files = Dir.entries(".")
    part_files = all_files.select do |file|
      file[/^#{filename}.Part[\d+]/]
    end

    File.delete(filename) if File.exists?(filename)
    part_files.size.times do |n|
      fn = "#{filename}.Part#{n+1}"
      File.append(filename, fn, size)
    end
    
    part_files.each { |fn| File.delete(fn) }
  end
  
  def multi_put_binary(remotefile, localfile = File.basename(remotefile),
                                        blocksize = DEFAULT_BLOCKSIZE, &block)
      
    puts "正在开发中。。。，还不支持多线程上传。"
    putbinaryfile(remotefile, localfile, blocksize, &block)
  end
end # MultiFTP class

