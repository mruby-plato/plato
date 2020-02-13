#
# temperature_sensor.rb - Temterature sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# TemperatureSensor class
class TemperatureSensor < ISensor
  # TemperatureSensor.new(sensor) #=> TemperatureSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @temp = sensor.instance
    @type = :temperature
  end

  # sonsor._read #=> Float
  def _read
    @temp.read_temperature
  end
end
