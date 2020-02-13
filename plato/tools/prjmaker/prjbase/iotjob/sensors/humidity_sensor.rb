#
# humidity_sensor.rb - Humidity sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# HumiditySensor class
class HumiditySensor < ISensor
  # HumiditySensor.new(sensor) #=> HumiditySensor
  #   sensor: Sensor class
  def initialize(sensor)
    @hum = sensor.instance
    @type = :humidity
  end

  # sensor._read #=> Float
  def _read
    @hum.read_humidity
  end
end
