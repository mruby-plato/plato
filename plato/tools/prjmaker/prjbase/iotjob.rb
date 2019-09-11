# criteria for vibration
VIBRATION_CRITERIA = 20

# low pass filter coefficient
VIB_FILTER_COEFFICIENT = 0.8
# vibration sampling cycle time
VIB_SAMPLING_CYCLE = 40

# ISensor class
# Base class of sensors
class ISensor
  # Get sensing data (or cached data)
  # isensor.read #=> Float/Array
  # <params>
  #   none.
  # <return>
  #   Float   Single value
  #   Array   List of values
  def read
    @value = _read unless @value
    return @value
  end

  # isensor.clear #=> nil
  # Clear cahced sensing data
  def clear
    @value = nil
  end

  # isensor.type #=> Symbol
  # Get sensor type. (e.g., :temperature, :humidity, ...)
  def type
    return @type  # TODO: Change to constant
  end

  # TODO: for test
  def value=(v)
    @value = v
  end

  def setup
  end
end

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

# AngleSensor class
class AngleSensor < ISensor
  # AngleSensor.new(sensor) #=> AngleSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @ang = sensor.instance
    @type = :angle
    @angle_crit = []      # criteria angle
    @save_angle = []      # angle for save value
    @use_crit = false     # use criteria angle (true: criteria angle、false: axis angle)
  end

  # angle.reset_angle_criteria
  # Set base angle
  def reset_angle_criteria
    @angle_crit = read_angle(false)
    @use_crit = true
  end

  # angle.release_angle_criteria
  # Release base angle
  def release_angle_criteria
    @use_crit = false
  end

  # angle.max #=> Float
  # Get maximum angle
  # <params>
  #   use:    Array of axis to calculate
  #           default: [:x, :y, :z]
  # <return>
  #   Float   Maximum angle [deg.]
  def max(use = [:x, :y, :z])
    value = read
    axis = []
    axis << value[0].abs if use.index(:x)
    axis << value[1].abs if use.index(:y)
    axis << value[2].abs if use.index(:z)
    return axis.max
  end

  # angle.min #=> Float
  # Get minimum angle
  # <params>
  #   use:    Array of axis to calculate
  #           default: [:x, :y, :z]
  # <return>
  #   Float   Minimum angle [deg.]
  def min(use = [:x, :y, :z])
    value = read
    axis = []
    axis << value[0].abs if use.index(:x)
    axis << value[1].abs if use.index(:y)
    axis << value[2].abs if use.index(:z)
    return axis.min
  end

  # angle._read #=> Array
  # Read 3-axis angles
  # <return>
  #   Array   Array of 3-axis angles [x, y, z]
  def _read
    val = read_angle
    return val
  end

  # read angle
  # whether or not data is being read is judged, and if it is read, reading is carried out
  # <params>　
  #   update     true       if it has not been updated, return empty array
  #              false      If it has not been updated, return previous value(default)
  # if reset_angle_criteria methode do, return angle is criteria angle
  # when return criteria angle, if don't set criteria angle, set criteria angle before return angle
  def read_angle(update = false)
    accel = @ang.read_acceleration
    angle = []
    unless accel.empty?
      x_square = accel[0] ** 2
      y_square = accel[1] ** 2
      z_square = accel[2] ** 2
      angle[0] = Math.atan(accel[0] / Math.sqrt(y_square + z_square)) * DEG / PI
      angle[1] = Math.atan(accel[1] / Math.sqrt(x_square + z_square)) * DEG / PI
      angle[2] = Math.atan(accel[2] / Math.sqrt(x_square + y_square)) * DEG / PI
      @save_angle = angle
    else
      angle = @save_angle unless update
    end

    if @use_crit
      @angle_crit = angle if @angle_crit.empty?

      angle[0] -= @angle_crit[0]
      angle[1] -= @angle_crit[1]
      angle[2] -= @angle_crit[2]
    end
    return angle
  end

  def setup
    @ang.setup
    reset_angle_criteria  # TODO: Refactor base angle initialize logic
  end
end

# VibrationSensor class
class VibrationSensor < ISensor
  # VibrationSensor.new(sensor) #=> VibrationSensor
  #   sensor: Sensor class
  def initialize(sensor)
    @vib = sensor.instance
    @type = :vibration
    @vib_status = false                                  # vibration status OFF: false, ON: true
    @vib_count = 0                                       # detect vibration count
    @vib_read = false                                    # read vibration

    @prev_time = 0                                       # previous time for vibration
    @vib_thresh = 0                                      # threshold for vibration
    @vib_crit = []                                       # criteria value for judge vibration
    @lpf = []                                            # low pass filter
    @prev_accel = []                                     # before acceleration value

    @sampling = IntervalTiming.new(VIB_SAMPLING_CYCLE)   # sampling cycle
    reset_threshold_vibration(VIBRATION_CRITERIA)        # reference value for judge detect vibration
  end

  # vibration.timing? => :none
  # when sampling time, detect vibration over reference
  def timing?
    if @sampling.timing? === :on
      vib = detect_vibration
      @vib_count += 1 if @vib_status && !vib  # ON->OFF
      @vib_status = vib
    end
    return :none
  end

  # vibration._read #=> Int
  # Read number of times over specified value
  def _read
    @vib_read = true
    return [@vib_count > 0, @vib_count]
  end

  def clear
    @value = nil
    @vib_count = 0 if @vib_read
    @vib_read = false
  end

  # detect vibration occor
  # return bool       vibration speed over criteria value, return true
  #                   vibration speed over criteria value, or acceleration don't read return false
  def detect_vibration
    accel = @vib.read_acceleration(true)

    # checke acceleraton value
    if accel.empty?
      return false
    end
    time = VM.tick

    # check vibration criteria
    @vib_crit = accel if @vib_crit.empty?

    vib_crit = @vib_crit
    # puts "read_accel: #{vib_crit}" if $DEBUG

    lpf = @lpf
    prev_accel = @prev_accel
    prev_time = @prev_time
    hpf = []      # high pass filter
    speed = []

    AXIS_SIZE.times{|i|
      accel[i] -= vib_crit[i]
      lpf[i] = accel[i] unless lpf[i]
      prev_accel[i] = accel[i] unless prev_accel[i]
      # clear noise
      lpf[i] = VIB_FILTER_COEFFICIENT * lpf[i] + accel[i] * (1 - VIB_FILTER_COEFFICIENT)
      # calculate high pass filter
      hpf[i] = accel[i] - lpf[i]
      # calculate speed
      speed[i] = ((hpf[i] + prev_accel[i]) * (time - prev_time)) / 2
      prev_accel[i] = hpf[i]

      speed[i] = speed[i].abs
      # puts "speed_axis#{i}: #{speed[i]}" if $DEBUG
    }

    @lpf = lpf
    @prev_accel = prev_accel
    @prev_time = time

    return speed.max > @vib_thresh
  end

  # set criteria value for acceleration
  def reset_accel_criteria
    @vib_crit = @vib.read_acceleration
    @prev_time = VM.tick
  end

  # threshold value for judge vibration
  # params    value    threshold value for judge vibration(mm/s)
  def reset_threshold_vibration(value)
    @vib_thresh = value
  end

  def setup
    @vib.setup
    reset_accel_criteria                                 # measurement reference value
  end
end

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

# IntervalTiming class
class IntervalTiming
  # IntervalTiming.new(cyvle) #=> IntervalTiming
  # <params>
  #   cycle:  interval time (milliseconds)
  def initialize(cycle)
    @cycle = cycle
    @timer = VM.tick   # Generate an event immediately after initialize
  end

  # Check timing
  # timing.timing? #=> true/false
  # <return>
  #   :on     It is time to execute action
  #   :none   It is not time to execute action
  def timing?
    return :on if @cycle == :test   # TODO : for test
    return :none if VM.tick < @timer
    @timer += @cycle
    return :on
  end

  # Restart timer
  # timing.restart #=> Fixmim
  def restart
    @timer = VM.tick   # Generate an event immediately after restart
  end
end

# Trigger timing
class TriggerTiming
  # TriggerTiming.new(job, period, judges, tail_edge, delay_time, cont_period) #=> TriggerTiming
  #   job:          Owner job
  #   judge_period: Period for trigger judgement
  #   judges:       Judgment conditions
  #   tail_edge:    Check tail-side edge
  #   delay_time:   Delay time for trigger-on (from trigger condition started)
  #   cont_period:  Period for while trigger on continues
  def initialize(job, judge_period, judges, tail_edge, delay_time = nil, cont_period = nil)
    @job = job
    @judge_timer = IntervalTiming.new(judge_period)   # trigger judge timer
    @judges = judges
    @enable_tail_edge = tail_edge
    @delay_time = delay_time      # TODO: implements
    @cont_period = cont_period    # TODO: implements
    @prev_trigger = false         # previous trigger condition
    sensors = []
    @judges.each{|judge|
      job.sensors.each{|sensor|
        sensors << sensor if sensor.type == judge[:type]
      }
    }
    @sensors = sensors
  end

  # Judge trigger timinig
  # TriggerTiming#timing? #=> :none/:on/:off
  # <return>
  #   :none   No trigger
  #   :on     Triggered head-side edge (off->on)
  #   :off    Triggered tail-side edge (on->off)
  def timing?
    # Check judge timing
    return :none if @judge_timer.timing? == :none

    trigger = :none
    # Get sensor values
    values = {}
    @sensors.each{|sensor|
      values[sensor.type] = (sensor.type === :angle) ? [sensor.max, sensor.min] : sensor.read   # TODO: refactpr max/min
    }
    # Judge trigger
    timing = judge_value(values)
    trigger = edge_decision(timing)
    # @prev_trigger = timing
    puts "trigger is #{trigger}" if $DEBUG

    return trigger
  end

  # timing.judge_value(values) #=> true/false
  # <params>
  #   values: Sensing values
  # <return>
  #   true:   It is time to execute action
  #   false:  It is not time to execute action
  def judge_value(values)
    jud_result = false
    timing = true
    @judges.each{|judge|
      return timing = false unless judge[:type] && judge[:value]
      ref_val = judge[:value].to_f
      if judge[:type] === :angle
        sen_val = case judge[:cond]
          when :gt, :ge, :eq, :ne;  values[judge[:type]][0] # max
          else;                     values[judge[:type]][1] # min
        end
      elsif judge[:type] === :vibration
        sen_val = values[judge[:type]][1]
      else
        sen_val = values[judge[:type]]
      end
      if $DEBUG
        print "#{judge[:and_or]} " if judge[:and_or]
        print "#{judge[:type]}(#{sen_val}) _#{judge[:cond]}_ #{judge[:value]}"
      end
      case judge[:cond]
        when :gt; jud_result = (sen_val >  ref_val) # greater than
        when :ge; jud_result = (sen_val >= ref_val) # greater than or equal
        when :le; jud_result = (sen_val <= ref_val) # less than or equal
        when :lt; jud_result = (sen_val <  ref_val) # less than
        when :eq; jud_result = (sen_val == ref_val) # equal
        when :nq; jud_result = (sen_val != ref_val) # not equal
        else;     jud_result = false                # others
      end
      puts " => #{jud_result.to_s}" if $DEBUG

      # and/or multiple judgment
      case judge[:and_or]
      when :and
        timing &&= jud_result
        return false unless timing
      when :or
        return true if timing
        timing ||= jud_result
      else  # 1st judgment
        timing = jud_result
      end
    }
    return timing
  end

  # timing.edge_decision(trigger) #=> :none/:on/:off
  # <params>
  #   trigger:  trigger status (true: triggered)
  # <return>
  #   :none   Edge not detected
  #   :on     Head-side edge detected
  #   :off    Tail-side edge detected
  def edge_decision(trigger)
    return :none if @prev_trigger == trigger
    if trigger  # off->on
      edge = :on
    else        # on->off
      edge = @enable_tail_edge ? :off : :none
    end
    @prev_trigger = trigger # Update previous trigger status
    return edge
  end

  # Restart timer
  # timing.restart #=> Fixmim
  def restart
    @judge_timer.restart
  end
end

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
      puts "ble.send :#{sensor.type}, #{sensor.read}" if $DEBUG
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
        else; puts "Unknown sensor type (#{sensor.type})" if $DEBUG
      end
    }
  end
end

# OnOffAction class
# Enable/Disable IoT job
class OnOffAction
  # OnOffAction.new(job_name, enable) #=> OnOffAction
  # <params>
  #   job_name: Job name to enable/disable
  #   enable:   Job state control (true:enable, false:disable)
  def initialize(job_name, enable)
    @job_name = job_name
    @job = nil
    @enable = enable
    # puts "Job(#{@job_name}) turn #{@enable ? 'on' : 'off'}" if $DEBUG
  end

  # action.run(trigger) #=> nil
  # <params>
  #   trigger:  Trigger type
  #     :on     head-side edge (off -> on)
  #     :off    tail-side edge (on -> off)
  def run(trigger = :on)
    @job = $app.job_list[@job_name.to_sym] unless @job  # at first time
    enable = @enable
    enable = !enable if (trigger == :off)
    @job.enable(enable)
    puts "IoTJob `#{@job.name}` #{@job.enabled? ? 'enabled' : 'disabled'}" if $DEBUG
  end
end

# IoT Job class
class IoTJob
  attr_reader :sensors
  attr_reader :timings
  attr_reader :actions
  attr_reader :name

  # IoTJob.new(name, enable)
  #   name:   Name of IoTJob
  #   enable: Initial state of IoT job.
  #             == true:  enable (as default)
  #             == false: disable
  def initialize(name, enable = true)
    @name = name
    @enable = enable
    @sensors = []
    @timings = []
    @actions = []
  end

  # iotjob.enable(ena) #=> true/false
  # Enable/Disable IoT job
  # Arguments
  #   ena:    Enable/Disable job
  #     true:   enable
  #     false:  disable
  def enable(ena)
    @enable = ena
    if ena
      @sensors.each{|sensor|
        sensor.setup
      }
      @timings.each{|timing|
        timing.restart
      }
    end
    puts "Job(#{@name}) turn #{ena ? 'on' : 'off'}" if $DEBUG
  end

  # iotjob.enabled? #=> true/false
  #   true:   IoT job is enabled
  #   false:  IoT job is disabled
  def enabled?
    return @enable
  end

  # iotjob.run #=> true/false
  def run
    return false unless @enable

    trigger = :none
    @timings.each{|timing|
      trigger = timing.timing?
      break if trigger != :none
    }
    if trigger != :none
      @actions.each{|action|
        action.run(trigger)
      }
    end
    # Clear sensor values
    # TODO: Re-design clear timing
    @sensors.each{|sensor|
      sensor.clear
    }
    true
  end
end

# IoT Application class
class Application
  # Application.new(name, jobs) #=> Application
  # <params>
  #   name:   Name of application
  #   jobs:   Array of IoT jobs
  def initialize(name, jobs)
    @name = name
    job_list = {}
    jobs.each{|job|
      job_list[job.name.to_sym] = job
      # setup sensors
      if job.enabled?
        job.sensors.each{|sensor|
          sensor.setup
        }
      end
    }
    @job_list = job_list
  end

  # Get job list
  def job_list
    return @job_list
  end

  # Run all jobs
  def run
    values = @job_list.values
    values.each{|value|
      value.run
    }
  end
end
