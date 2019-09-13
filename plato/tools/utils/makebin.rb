#!/usr/bin/env ruby

#
# constants
#
HEADER = 'mruby ' + Time.now.strftime('%y%m%d%H%M') # 'mruby yymmddhhMM' (16 chars)
MAX_BINARIES  = 3
OFFSET_SIZE   = 4

CRC16BIT  = 0xa001
CRC16INIT = 0xffff

#
# functions
#

# 32bit intefer convert to 4 byte string (Little Endian)
def int2str(dw)
  (dw & 0xff).chr + ((dw >> 8) & 0xff).chr + ((dw >> 16) & 0xff).chr + ((dw >> 24) & 0xff).chr
end

# Update CRC16 value
# _crc16(crc, byte) => Fixnum
# <params>
#   crc:  Current CRC16 value
#   byte: byte data
# <return>
#   Updated CRC16 value
def _crc16(crc, byte)
  crc ^= byte
  8.times {|bit|
    x = (crc & 0x0001) != 0
    crc >>= 1
    crc ^= CRC16BIT if x
  }
  crc
end

# Calculation CRC16
# crc16(data) => Fixnum
# <params>
#   data: binary data (String)
# <return>
#   CRC16
def crc16(data)
  crc = CRC16INIT
  data.each_byte {|byte|
    crc = _crc16(crc, byte)
  }
  crc
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

ofst = HEADER.size + (bins.size + 2) * 4  # +2 : bin_count + crc_offset
offsets = int2str(bins.size)  # Number of binaries

bins.each_with_index {|bin, i|
  offsets += int2str(ofst)
  puts "src#{i}: offset=#{ofst} (0x#{ofst.to_s(16)})" if $DEBUG
  ofst += bin.size
}
offsets += int2str(ofst)  # CRC offset

# build up bindata
bindata = HEADER +    # signeture and timestamp
          offsets +   # offsets of binary
          bins.join   # binaries

crc = crc16(bindata)

# Write binary amd CRC16 to bin file
File.open(dst, 'wb') {|wf|
  wf.write bindata
  wf.write [crc].pack("S<") # CRC16 (little-endian)
}

puts "#{dst} is written. (size=#{File.size(dst)}, crc=0x#{crc.to_s(16)})"
