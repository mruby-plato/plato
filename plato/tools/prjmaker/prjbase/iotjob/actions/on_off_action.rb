#
# on_off_action.rb - On/Off action class
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

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
    # puts "IoTJob `#{@job.name}` #{@job.enabled? ? 'enabled' : 'disabled'}" if $DEBUG
  end
end
