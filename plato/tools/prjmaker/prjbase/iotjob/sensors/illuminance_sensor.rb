#
# illuminance_sensor.rb - Illuminance sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# IlluminanceSensor class
class IlluminanceSensor < ISensor
  # IlliminanceSensor.new(sensor) #=> IlliminanceSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @illu = sensor.instance
    @type = :illuminance
  end

  # sonsor._read #=> Float
  def _read
    @illu.read_lux
  end

  def setup
    @illu.setup
  end
end
