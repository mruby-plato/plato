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
        sentyp = judge[:type].to_s.split('__')[0] # get sensor type
        sensors << sensor if sensor.type == sentyp.to_sym
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
      sensor.clear  # refresh sensor value
      values[sensor.type] = sensor.read
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
      return false unless judge[:type] && judge[:value]
      ref_val = judge[:value].to_f
      types = judge[:type].to_s.split('__')
      sentyp = types[0].to_sym                # Symbol of sensor type
      vidx = types[1] ? types[1].to_i : nil   # index in array of values
      if sentyp == :vibration
        sen_val = values[:vibration][1] # vibration.count
      elsif vidx
        sen_val = values[sentyp][vidx]  # values[type][vidx] (e.g., angle.x, y, z)
      else
        sen_val = values[sentyp]        # values[type]
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
      print "#{judge[:and_or]} " if judge[:and_or]
      print "#{sentyp}(#{sen_val}) _#{judge[:cond]}_ #{judge[:value]}"
      puts " => #{jud_result.to_s}"

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
