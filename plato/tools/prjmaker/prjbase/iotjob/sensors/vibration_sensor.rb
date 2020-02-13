#
# vibration_sensor.rb - Vibration sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#
# Note
#   Depends IntervalTiming class
#

# criteria for vibration
VIBRATION_CRITERIA = 20
# low pass filter coefficient
VIB_FILTER_COEFFICIENT = 0.8
# vibration sampling cycle time
VIB_SAMPLING_CYCLE = 40

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
