#
# interval_timing.rb - Intarval timing class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

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
