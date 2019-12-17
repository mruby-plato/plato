#
# air_pressure_sensor.rb - Air pressure sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# AirPressureSensor class
class AirPressureSensor < ISensor
  # AirPressureSensor.new(sensor) #=> AirPressureSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @sensor = sensor.instance
    @type = :air_pressure
  end

  # sensor._read #=> Float
  def _read
    @sensor.read_air_pressure
  end
end
