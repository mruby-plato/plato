#
# bluetooth_action.rb - Bluetooth action class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# BluetoothAction class
class BluetoothAction
  # BluetoothAction.new(job, sensor) #=> BluetoothAction
  # <params>
  #   job:      Owner job
  #   sensors:  Array of sensor class to send value
  def initialize(job, sensors)
    use_sensors = []
    job.sensors.each{|job_sensor|
      use_sensors.push(job_sensor) if sensors.index(job_sensor.type)
    }
    @sensors = use_sensors
  end

  # Send values to Bluetooth
  # bt.run #=> nil
  # <params>
  #   trigger:  Don't care
  def run(trigger = :on)
    @sensors.each{|sensor|
      # puts "ble.send :#{sensor.type}, #{sensor.read}" if $DEBUG
      # Send value
      # BLE.notify(sensor.type, sensor.read)
      case sensor.type
        when :acceleration; BLE.acceleration = sensor.read
        when :angle;        BLE.gyro = sensor.read
        when :temperature;  BLE.temperature = sensor.read
        when :humidity;     BLE.humidity = sensor.read
        when :air_pressure; BLE.air_pressure = sensor.read
        when :illuminance;  BLE.illuminance = sensor.read
        when :gpsgga;       BLE.gps_gga = sensor.read
        when :gpsvtg;       BLE.gps_vtg = sensor.read
        when :battery;      BLE.battery = sensor.read
        when :vibration;    BLE.vibration = sensor.read
        else; # puts "Unknown sensor type (#{sensor.type})" if $DEBUG
      end
    }
  end
end
