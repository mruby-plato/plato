#!/usr/bin/env ruby
#
# rebuild.rb - Re-build Plato project
# 
# ruby rebuild [app_path]
#   app_path: application directory.
#
require 'fileutils'
require 'json'
require 'erb'
require 'logger'

#
# functions
#

# # tab
# def tab(str, n=1, chr='  ')
#   chr * n + str
# end

$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG if $DEBUG

begin

#
# main
#

# Check argument
if ARGV.size < 1
  puts <<"EOS"
Usage: #{$0} app_path
  app_path: application directory
EOS
  exit(1)
end
# $logger.debug "#{$0} #{ARGV[0]}"
puts "#{$0} #{ARGV[0]}"
app_path = ARGV[0]

# Get Plato environment ($HOME/.plato/plato2.cfg)
begin
  platoenv = File.join(Dir.home, '.plato', 'plato2.cfg')
  env = JSON::parse(File.read(platoenv))
rescue
  env = {}
end
# $logger.debug "env: #{env}"

# Get platform
$exe = ''
$platform = case RUBY_PLATFORM.downcase
when /mswin(?!ce)|mingw|cygwin|bccwin/
  $exe = '.exe'
  :windows
when /darwin/
  :mac
when /linux/
  :linux
else
  :other
end
# $logger.debug "platform: #{$platform}"

# Get project root directory
homedir = $platform == :windows ? 'C:' : Dir.home
platoroot = env['instdir'] ? env['instdir'] : File.join(homedir, 'plato2')
# $logger.debug "platoroot: #{platoroot}"

# re-init logger
$logger = Logger.new(File.join(platoroot, '.plato', 'plato2.log'))
$logger.level = Logger::DEBUG if $DEBUG

# Get project base directory (plato2/.plato/prjbase)
$prjbase = File.join(platoroot, '.plato', 'prjbase')

# Load application configuration
app_json = File.join(app_path, 'app.json');
appcfg = JSON::parse(File.read(app_json))
$logger.debug "app.json: #{app_json}"
$logger.debug "appcfg: #{appcfg}"

# Make project directories
# prjdir = File.join(platoroot, appcfg['name'].gsub(' ', '_'))
prjdir = app_path
bindir = File.join(prjdir, 'bin')
libdir = File.join(prjdir, 'mrblib')
# [prjdir, bindir, libdir].each {|dir|
#   FileUtils.mkdir_p(dir) unless File.exist?(dir)
# }
$logger.info "App.dir: #{prjdir}"

# # Copy files into project directory
# [
#   File.join($prjbase, 'Rakefile')
# ].each {|fn|
#   FileUtils.cp(fn, File.join(prjdir, File.basename(fn)))
# }
# # selected-mrbgems.lst
# # FileUtils.cp(mgemlist, File.join(prjdir, 'selected-mrbgems.lst'))

# #
# # Make app_edge.rb
# #

# JOBS = []
# SENSORS = {
#   :acceleration => {:cls => 'AccelerationSensor', :dev => 'ACCELERATION_SENSOR',  :src => 'sensors/acceleration_sensor.rb'},
#   :gyro         => {:cls => 'GyroSensor',         :dev => 'GYRO_SENSOR'},
#   :geomagnetism => {:cls => 'GeomagnetismSensor', :dev => 'GEOMAGNETISM_SENSOR'},
#   :temperature  => {:cls => 'TemperatureSensor',  :dev => 'TEMPERATURE_SENSOR',   :src => 'sensors/temperature_sensor.rb'},
#   :humidity     => {:cls => 'HumiditySensor',     :dev => 'HUMIDITY_SENSOR',      :src => 'sensors/humidity_sensor.rb'},
#   :air_pressure => {:cls => 'AirPressureSensor',  :dev => 'AIR_PRESSURE_SENSOR',  :src => 'sensors/air_pressure_sensor.rb'},
#   :illuminance  => {:cls => 'IlluminanceSensor',  :dev => 'ILLUMINANCE_SENSOR',   :src => 'sensors/illuminance_sensor.rb'},
#   :location     => {:cls => 'GPSGGA',             :dev => 'GPS_DEVICE',           :src => 'sensors/gps_gga.rb'},
#   :velocity     => {:cls => 'GPSVTG',             :dev => 'GPS_DEVICE'},
#   :vibration    => {:cls => 'VibrationSensor',    :dev => 'VIBRATION_SENSOR',     :src => ['sensors/vibration_sensor.rb', 'timings/interval_timing.rb']},
#   :angle        => {:cls => 'AngleSensor',        :dev => 'ANGLE_SENSOR',         :src => 'sensors/angle_sensor.rb'},
#   :battery      => {:cls => 'Battery',            :dev => '',                     :src => 'sensors/battery_level.rb'},
#   :custom       => {:cls => 'Custom',             :dev => ''},
# }
# TIMINGS = {
#   :interval     => {:cls => 'IntervalTiming',     :src => 'timings/interval_timing.rb'},
#   :ontime       => {:cls => 'OnTimeTiming',       :src => 'timings/ontime_timing.rb'},
#   :part_time    => {:cls => 'PartTimeTiming'},
#   :trigger      => {:cls => 'TriggerTiming',      :src => ['timings/trigger_timing.rb', 'timings/interval_timing.rb']},
# }
# ACTIONS = {
#   :bluetooth    => {:cls => 'BluetoothAction',    :src => 'actions/bluetooth_action.rb'},
#   :onoff        => {:cls => 'OnOffAction',        :src => 'actions/on_off_action.rb'},
#   :gpio         => {:cls => 'GPIOAction',         :src => 'actions/gpio_action.rb'},
# }

# $libsrcs = ['iotjobcore.rb']

# # build up IoTJob's sensors
# def build_job_sensor(sen, t)
#   # tab('ISensor.new(:' + sen['type'] + '),', t)
#   sensor = SENSORS[sen['type'].to_sym]
#   # Add library source
#   $libsrcs << sensor[:src] if sensor[:src] # add libsrcs
#   tab("job.sensors << #{sensor[:cls]}.new(#{sensor[:dev]})", t)
# end

# HOUR_SECONDS = 3600
# MINUTE_SECONDS = 60

# # build up IoTJob's timings
# def build_job_timing(tim, t)
#   # Add library source
#   sym = tim['type'].to_sym
#   $libsrcs << TIMINGS[sym][:src] if TIMINGS[sym][:src] # add libsrcs

#   # timing = TIMINGS[tim['type'].to_sym]
#   params = tim['params']
#   header = 'job.timings << '

#   case tim['type']
#   when 'interval'
#     sec = params['interval_time'].to_i * 1000 # millisecond -> second
#     case params['interval_time_unit']
#     when 'hour'
#       sec *= HOUR_SECONDS
#     when 'minute'
#       sec *= MINUTE_SECONDS
#     end
#     tab("#{header}IntervalTiming.new(#{sec})", t)

#   when 'trigger'
#     timing = []
#     timing << tab('judges = []', t)
#     params['triggers'].each {|trig|
#       and_or = trig['and_or'] ? "and_or: :#{trig['and_or']}, " : ''
#       judge = "type: :#{trig['param']}, value: #{trig['value']}, cond: :#{trig['cond']}"
#       timing << tab("judges << {#{and_or}#{judge}}", t)
#     }
#     sec = params['trig_period'].to_i * 1000 # millisecond -> second
#     case params['trig_peri_unit']
#     when 'hour'
#       sec *= HOUR_SECONDS
#     when 'minute'
#       sec *= MINUTE_SECONDS
#     end
#     timing << tab("#{header}TriggerTiming.new(job, #{sec}, judges, #{params['trig_off']})", t)

#   when 'ontime'
#     ontimes = []
#     params['times'].sort.each {|tm|
#       h, m = tm.split(':').map {|t| t.to_i}
#       ontimes << "DateTime.time(#{h}, #{m})"
#     }
#     tab("#{header}OnTimeTiming.new([#{ontimes.join(', ')}])", t)

#   when 'part_time'
#     # TODO: implements
#   end
# end

# LEDCOLORS = ['nil', ':red', ':green', ':blue']

# # build up IoTJob's actions
# def build_job_action(act, t)
#   # Add library source
#   sym = act['type'].to_sym
#   $libsrcs << ACTIONS[sym][:src] if ACTIONS[sym][:src]

#   # action = ACTIONS[act['type'].to_sym]
#   params = act['params']
#   header = 'job.actions << '
#   case act['type']
#   when 'bluetooth'
#     values = params.inject([]) {|ary, (k, v)|
#       ary << ":#{k}" if v
#     }
#     tab("#{header}BluetoothAction.new(job, [#{values.join(', ')}])", t)
#   when 'onoff'
#     tab("#{header}OnOffAction.new(#{JOBS[params['jobid'].to_i].inspect}, #{params['onoff'].to_i != 0})", t)
#   when 'gpio'
#     tab("#{header}GPIOAction.new(#{LEDCOLORS[params['pin'].to_i]}, :#{params['value']})", t)
#   end
# end

# # build up IoTJobs
# def build_job(job, t=0)
#   # JOBS[job['id']] = job['name']
#   ja = []
#   ja << tab("# #{job['name']}", t)
#   ja << tab("JOBS << job = IoTJob.new(#{job['name'].inspect}, #{(job['onoff'] == 'on')})", t)
#   job['sensor'].each {|sen|
#     ja << build_job_sensor(sen, t)
#   }
#   job['timing'].each {|tim|
#     ja << build_job_timing(tim, t)
#   }
#   job['action'].each {|act|
#     ja << build_job_action(act, t)
#   }
#   ja.join("\n")
# end

# jobs = appcfg['jobList']
# jobs.each {|job|
#   JOBS[job['id']] = job['name']
# }
# job_list = jobs.map() {|job|
#   puts "job: #{job['name']}"
#   build_job(job)
# }.join("\n")

# appscript = ERB.new(File.read(File.join($prjbase, 'app_edge.erb'))).result
app_edge_rb = File.join(prjdir, 'app_edge.rb')
# File.write(app_edge_rb, appscript)
# $logger.info "`#{app_edge_rb}` is written."

# # build up iotjob.rb
# $logger.debug "libsrcs: `#{$libsrcs}`"
# $libsrcs = $libsrcs.flatten.uniq
# iotjob_srcs = []
# $libsrcs.each {|src|
#   iotjob_srcs << File.read(File.join($prjbase, 'iotjob', src))
# }
# File.write(File.join(prjdir, 'iotjob.rb'), iotjob_srcs.join("\n"))

# def hex2str(hex)
#   str = ''
#   (hex.size / 2).to_i.times {|i|
#     str += hex[i*2, 2].to_i(16).chr
#   }
#   str
# end

# #
# # Make app_edge_init_XXXXXX.rb
# #

setting = appcfg['setting']
bt_setting = setting['bt_setting']
# # Device name
# devname = bt_setting['devname']
# devname = nil if devname.nil? || devname.length == 0
# # Proximity UUID
# grpid = bt_setting['grpid'].gsub('-', '')
# proximity = grpid.length == 32 ? hex2str(grpid) : nil
# Major / Minor
devid = bt_setting['devid']
devid = '000000' if devid.nil? || devid.length < 6
# Device IDs
devids = []
devcnt = bt_setting['devcnt'].to_i
devcnt = 1 if devcnt == 0
devcnt.times {|i|
  devids << sprintf("%06X", devid.to_i(16) + i)
}

# major, minor = '', ''
# devids.each {|devid|
#   # Major / Minor
#   major = hex2str(devid[0, 2])
#   minor = hex2str(devid[2, 4])
#   # build script
#   rbfile = "app_edge_init_#{devid}.rb"
#   appscript = ERB.new(File.read(File.join($prjbase, 'app_edge_init.erb'))).result
#   app_edge_init_rb = File.join(prjdir, rbfile)
#   File.write(app_edge_init_rb, appscript)
#   $logger.info "`#{rbfile}` is written."
# }

# #
# # Make app_bridge_init.rb
# #

# devname = nil
# # LoRa parameters
# lora_setting = setting['lora_setting']
# lora_deveui = lora_setting['deveui'].length == 16 ? hex2str(lora_setting['deveui']) : nil
# lora_appeui = lora_setting['appeui'].length == 16 ? hex2str(lora_setting['appeui']) : nil
# lora_appkey = lora_setting['appkey'].length == 32 ? hex2str(lora_setting['appkey']) : nil

# appscript = ERB.new(File.read(File.join($prjbase, 'app_bridge_init.erb'))).result
# # puts appscript if $DEBUG
# app_bridge_init_rb = File.join(prjdir, 'app_bridge_init.rb')
# File.write(app_bridge_init_rb, appscript)
# $logger.info "`#{app_bridge_init_rb}` is written."

# #
# # Make app_bridge.rb
# #

# appscript = ERB.new(File.read(File.join($prjbase, 'app_bridge.erb'))).result
# # puts appscript if $DEBUG
# app_bridge_rb = File.join(prjdir, 'app_bridge.rb')
# File.write(app_bridge_rb, appscript)
# $logger.info "`#{app_bridge_rb}` is written."

#
# Compile ruby scripts and generate application binaries
#

platotool = File.join(platoroot, '.plato', 'tools')
mrbc201 = File.join(platotool, "mrbc201#{$exe}")

app_edge_bg_rb = File.join($prjbase, 'app_edge_bg.rb')
iotjob_rb = File.join(prjdir, 'iotjob.rb')
makebin_rb = File.join(platotool, "makebin.rb")

app_edge_init_mrb = File.join(bindir, 'app_edge_init.mrb')
app_edge_bg_mrb = File.join($prjbase, 'app_edge_bg.mrb')
app_edge_mrb = File.join(bindir, 'app_edge.mrb')

`#{mrbc201} -E -o #{app_edge_bg_mrb} #{app_edge_bg_rb}`
$logger.info "`#{app_edge_bg_rb}` is compiled."

`#{mrbc201} -E -o #{app_edge_mrb} #{app_edge_rb}`
$logger.info "`#{app_edge_rb}` is re-compiled."

devids.each {|devid|
  rbfile = "app_edge_init_#{devid}.rb"
  app_edge_init_rb = File.join(prjdir, rbfile)
  `#{mrbc201} -E -o #{app_edge_init_mrb} #{iotjob_rb} #{app_edge_init_rb}`
  $logger.info "`#{app_edge_init_rb}` is compiled."

  app_edge_bin = File.join(bindir, "edge_#{devid}.bin")
  `ruby #{makebin_rb} #{app_edge_bin} #{app_edge_init_mrb} #{app_edge_bg_mrb} #{app_edge_mrb}`
  $logger.info "#{app_edge_bin} is generated."
  puts "#{app_edge_bin} is generated."
}

# app_bridge_init_mrb = File.join(bindir, 'app_bridge_init.mrb')
# app_bridge_mrb = File.join(bindir, 'app_bridge.mrb')

# `#{mrbc201} -E -o #{app_bridge_init_mrb} #{app_bridge_init_rb}`
# $logger.info "`#{app_bridge_init_rb}` is compiled."

# `#{mrbc201} -E -o #{app_bridge_mrb} #{app_bridge_rb}`
# $logger.info "`#{app_bridge_rb}` is compiled."

# app_bridge_bin = File.join(bindir, "bridge.bin")
# `ruby #{makebin_rb} #{app_bridge_bin} #{app_bridge_init_mrb} #{app_bridge_mrb}`
# $logger.info "#{app_bridge_bin} is generated."

# #
# # Launch Visual Studio Code
# #
# code = "code"
# if $platform == :mac
#   if `which code`.chomp.size == 0
#     code = "open -a /Applications/Visual\\ Studio\\ Code.app"
#   end
# end
# # `#{code} #{platoroot} #{app_edge_rb} #{app_edge_init_rb} #{app_bridge_rb} #{app_bridge_init_rb}`
# `#{code} #{platoroot} #{app_edge_rb} #{app_bridge_rb} #{app_bridge_init_rb}`
# $logger.info 'VSCode launched.'

rescue => e
  $logger.error e
end
