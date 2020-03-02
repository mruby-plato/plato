#
# gps_gga.rb - GPS GGA class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# GPSGGA class
class GPSGGA < ISensor
  # GPSGGA.new(gps) #=> GPSGGA
  #   gps: GPS class
  def initialize(gps)
    @gps = gps.instance
    @type = :gpsgga
  end

  # sonsor._read #=> Array (as [utc, lat, lng, hdop])
  def _read
    # get position
    pos = @gps.position # [lat, lnt, hdop]
    return nil if pos.size < 3 || pos[0].nil? || pos[1].nil? || pos[2].nil?
    # get UTC
    utc = @gps.gga[:time]
    ary = [utc, pos[0], pos[1], pos[2]]
    puts "GPSGGA#_read: #{ary.inspect}"
    ary
  end
end
