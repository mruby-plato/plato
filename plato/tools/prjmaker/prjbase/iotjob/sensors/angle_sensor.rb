#
# angle_sensor.rb - Angle sensor class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

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
    accel = @ang.read_acceleration(update)
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
