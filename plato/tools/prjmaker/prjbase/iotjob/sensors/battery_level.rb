#
# battery_level.rb - Battery level class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

BATTERY_LOW = 10  # 10%

# BatteryLevel class
class BatteryLevel < ISensor
  # BatteryLevel.new(bat) #=> BatteryLevel
  # <params>
  #   bat:    Battery object
  def initialize(bat)
    @bat = bat.instance
    @type = :battery
  end

  # battery._read #=> Fixnum
  def _read
    level = @bat.level
    [level <= BATTERY_LOW, level]
  end

  # battery.setup
  def setup
    @bat.level
  end
end
