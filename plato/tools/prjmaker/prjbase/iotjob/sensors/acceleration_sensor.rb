#
# acceleration_sensor.rb - Acceleration sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# AccelerationSensor class
class AccelerationSensor < ISensor
  # AccelerationSensor.new(sensor) #=> AccelerationSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @accel = sensor.instance
    @type = :acceleration
  end

  # sonsor._read #=> Array (as [x, y, z])
  def _read
    @accel.read_acceleration
  end

  def setup
    @accel.setup
  end
end
