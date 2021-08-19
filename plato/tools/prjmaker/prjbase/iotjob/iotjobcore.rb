#
# iotjobcore.rb - IoT job core library
#
# Copyright(c) 2019 Braveridge Co,. Ltd.
# Copyright(c) 2019 Kyushu Institute of Technology
# Copyright(c) 2019 SCSK KYUSHU CORPORATION
# Copyright(c) 2019 International Laboratory Corporation
#

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

  def timing?
    :none
  end

  def setup
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
    # puts "Job(#{@name}) turn #{ena ? 'on' : 'off'}" if $DEBUG
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

    # Read data
    @sensors.each {|sensor|
      sensor.timing?
    }

    trigger = :none
    @timings.each {|timing|
      trigger = timing.timing?
      break if trigger != :none
    }
    if trigger != :none
      @actions.each {|action|
        action.run(trigger)
      }
      # Clear sensor values
      # TODO: Re-design clear timing
      @sensors.each {|sensor|
        sensor.clear
      }
    end
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
