# multi-ftp

## Description
ruby标准库ftp类扩展的多线程ftp。
学习编程刚刚入门，发个小程序，希望大家不吝指教！
现有问题：
* 只有多线程下载，上传功能还没弄
* 不够健壮，基本没有异常处理

## Installation
from the git repository on github:

    git clone https://github.com/samuelnian/multi-ftp.git
    cd multi-ftp
    gem build multi_ftp.gemspec
    gem install multi-ftp-0.0.1.gem -l

## Example
```ruby
require 'multi_ftp'

mftp = MultiFTP.new("localhost", nil, "1", "1")
puts mftp.sendcmd("pwd")
puts mftp.list
mftp.get "xp.iso"
mftp.close
```
