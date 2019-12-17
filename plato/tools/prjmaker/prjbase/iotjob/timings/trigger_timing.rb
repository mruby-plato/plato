#
# trigger_timing.rb - Trigger timing class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#
# Note
#   Depends IntervalTiming class
#

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
    # puts "trigger is #{trigger}" if $DEBUG

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
      # if $DEBUG
      #   print "#{judge[:and_or]} " if judge[:and_or]
      #   print "#{judge[:type]}(#{sen_val}) _#{judge[:cond]}_ #{judge[:value]}"
      # end
      case judge[:cond]
        when :gt; jud_result = (sen_val >  ref_val) # greater than
        when :ge; jud_result = (sen_val >= ref_val) # greater than or equal
        when :le; jud_result = (sen_val <= ref_val) # less than or equal
        when :lt; jud_result = (sen_val <  ref_val) # less than
        when :eq; jud_result = (sen_val == ref_val) # equal
        when :nq; jud_result = (sen_val != ref_val) # not equal
        else;     jud_result = false                # others
      end
      # puts " => #{jud_result.to_s}" if $DEBUG

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
