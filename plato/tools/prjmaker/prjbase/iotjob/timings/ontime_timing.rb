#
# ontime_timing.rb - On time timing class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

# OnTimeTiming class
class OnTimeTiming
  # OnTimeTiming.new(t) #=> OnTimeTiming
  # <params>
  #   tm: Specified times
  def initialize(tm)
    @tm = (tm.class == Array) ? tm : [tm]
    @target = nil
  end

  # re-schedule target timing
  # timing.reschedule #=> DateTime
  def reschedule(now = nil)
    now = DateTime.now unless now
    # puts "DateTime#reschedule start: now=#{now}"

    target = nil
    # Seek target time (today)
    @tm.each {|tm|
      dtm = DateTime.new(now.year, now.month, now.day, tm.hour, tm.minute)
      # return dtm if dtm > now # disable OP_RETUR_BLK
      unless now.passed?(dtm)
        target = dtm
        break
      end
    }
    if target
      # puts "DateTime#reschedule end: target=#{target}"
      return target
    end

    # Return tomorrow's first target time
    now.tomorrow!
    return DateTime.new(now.year, now.month, now.day, @tm[0].hour, @tm[0].minute)
  end

  # Check timing
  # timing.timing? #=> true/false
  # <return>
  #   :on     It is time to execute action
  #   :none   It is not time to execute action
  def timing?
    return :none unless SystemTime.available?
    return :none unless @target

    now = DateTime.now
    return :none unless now.passed?(@target)

    # Re-schedule target time
    @target = reschedule(now)
    return :on
  end

  # Restart timer
  # timing.restart #=> Fixmim
  def restart
    return unless SystemTime.available?
    @target = reschedule
  end
end
