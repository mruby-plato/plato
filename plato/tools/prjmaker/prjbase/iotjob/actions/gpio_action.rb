#
# gpio_action.rb - GPIO action class
#
# Copyright(c) 2020 Braveridge Co,. Ltd.
# Copyright(c) 2020 Kyushu Institute of Technology
# Copyright(c) 2020 SCSK KYUSHU CORPORATION
# Copyright(c) 2020 International Laboratory Corporation
#

# OnOffAction class
# Enable/Disable IoT job
class GPIOAction
  # GPIOAction.new(pin, init = :off) #=> GPIOAction
  # <params>
  #   pin:  GPIO pin number/name
  #   init: GPIO initial state (nil/:on/:off)
  def initialize(pin, init = nil)
    @pin = pin
    if init
      # TODO: Output initial value
    end
  end

  # action.run(trigger) #=> nil
  # <params>
  #   trigger:  Trigger type
  #     :on     head-side edge (off -> on)
  #     :off    tail-side edge (on -> off)
  def run(trigger = :on)
    io = case @pin
      when :red, :green, :blue
        $sx.led(@pin)
      else
        nil
    end
    if io
      (trigger == :on || trigger == :high) ? io.on : io.off
    end
  end
end
