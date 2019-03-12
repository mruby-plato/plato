#!/usr/bin/env ruby

#
# constants
#
HEADER = 'mruby ' + Time.now.strftime('%y%m%d%H%M') # 'mruby yymmddhhMM' (16 chars)
MAX_BINARIES  = 3
OFFSET_SIZE   = 4

#
# functions
#

# 32bit intefer convert to 4 byte string (Little Endian)
def int2str(dw)
  (dw & 0xff).chr + ((dw >> 8) & 0xff).chr + ((dw >> 16) & 0xff).chr + ((dw >> 24) & 0xff).chr
end

#
# main
#

if ARGV.size < 2
  puts <<EOS
Usage: #{$0} <binfile> mrbfile1 [mrbfile2 [...]]
  binfile:      Output file name (*.bin)
  mrbfile1..N:  mrb files.
EOS
end

dst = ARGV.shift

bins = []
ARGV.each {|src|
  File.open(src, 'rb') {|rf|
    bin = rf.read
    bin += ("\x00" * (4 - (bin.size % 4)) % 4)  # add padding
    bins << bin
    puts "#{src}: size=#{bin.size}" if $DEBUG
  }
}

ofst = HEADER.size + (bins.size + 1) * 4
offsets = int2str(bins.size)  # Number of binaries

bins.each_with_index {|bin, i|
  offsets += int2str(ofst)
  puts "src#{i}: offset=#{ofst} (0x#{ofst.to_s(16)})" if $DEBUG
  ofst += bin.size
}

File.open(dst, 'wb') {|wf|
  # write signeture and timestamp
  wf.write HEADER
  # write offsets of binary
  wf.write offsets
  # write binaries
  wf.write bins.join
}

puts "#{dst} is written. (size=#{File.size(dst)})"
