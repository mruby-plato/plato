puts "+++ app_edge_bg.rb +++"

#
# Global variables
#

$DEBUG = true   # debug mode

$gps = RTL8771B.new(UART.new)

while true
  # parse GPS data
  $gps.parse if $gps

  # Don't care
  sleep_ms(1)
end
