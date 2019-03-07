#!/usr/bin/env ruby
#
# prjmaker.rb - Plato project maker
# 
# ruby prjmaker <app_path>
#   app_path: application directory.
#
require 'fileutils'
require 'json'
require 'erb'
require 'logger'
# require 'resolv'

#
# functions
#

# tab
def tab(str, n=1, chr='  ')
  chr * n + str
end

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

$logger.debug "prjmaker.rb #{ARGV[0]}"
app_path = ARGV[0]

# Get Plato environment ($HOME/.plato/plato2.cfg)
begin
  platoenv = File.join(Dir.home, '.plato', 'plato2.cfg')
  env = JSON::parse(File.read(platoenv))
rescue
  env = {}
end
$logger.debug "env: #{env}"

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
$logger.debug "platform: #{$platform}"

# Get project root directory
homedir = $platform == :windows ? 'C:' : Dir.home
platoroot = env['instdir'] ? env['instdir'] : File.join(homedir, 'plato2')
$logger.debug "platoroot: #{platoroot}"

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
prjdir = File.join(platoroot, appcfg['name'].gsub(' ', '_'))
bindir = File.join(prjdir, 'bin')
libdir = File.join(prjdir, 'mrblib')
[prjdir, bindir, libdir].each {|dir|
  FileUtils.mkdir_p(dir) unless File.exist?(dir)
}
$logger.info "App.dir: #{prjdir}"

# Copy files into project directory
[
  File.join($prjbase, 'Rakefile')
].each {|fn|
  FileUtils.cp(fn, File.join(prjdir, File.basename(fn)))
}
# selected-mrbgems.lst
# FileUtils.cp(mgemlist, File.join(prjdir, 'selected-mrbgems.lst'))

#
# Make app_edge.rb
#

JOBS = []
SENSORS = {
  :acceleration => {:cls => 'AccelerationSensor', :dev => 'ACCELERATION_SENSOR'},
  :gyro         => {:cls => 'GyroSensor',         :dev => 'GYRO_SENSOR'},
  :geomagnetism => {:cls => 'GeomagnetismSensor', :dev => 'GEOMAGNETISM_SENSOR'}, 
  :temperature  => {:cls => 'TemperatureSensor',  :dev => 'TEMPERATURE_SENSOR'},
  :humidity     => {:cls => 'HumiditySensor',     :dev => 'HUMIDITY_SENSOR'},
  :air_pressure => {:cls => 'AirPressureSensor',  :dev => 'AIR_PRESSURE_SENSOR'},
  :illuminance  => {:cls => 'IlluminanceSensor',  :dev => 'ILLUMINANCE_SENSOR'},
  :gps_gga      => {:cls => 'GPSGGA',             :dev => 'GPS_DEVICE'},
  :gps_vtg      => {:cls => 'GPSVTG',             :dev => 'GPS_DEVICE'},
  :battery      => {:cls => 'Battery',            :dev => ''},
  :custom       => {:cls => 'Custom',             :dev => ''},
}
# TIMINGS = {
#   :interval     => {:cls => 'IntervalTiming'},
#   :ontime       => {:cls => 'OnTimeTiming'},
#   :part_time    => {:cls => 'PartTimeTiming'},
#   :trigger      => {:cls => 'TriggerTiming'},
# }
# ACTIONS = {
#   :bluetooth    => {:cls => 'BluetoothAction'},
#   :onoff        => {:cls => 'OnOffAction'},
#   :gpio         => {:cls => 'GPIOAction'},
# }

# build up IoTJob's sensors
def build_job_sensor(sen, t)
  # tab('ISensor.new(:' + sen['type'] + '),', t)
  sensor = SENSORS[sen['type'].to_sym]
  tab("job.sensors << #{sensor[:cls]}.new(#{sensor[:dev]})", t)
end

HOUR_SECONDS = 3600
MINUTE_SECONDS = 60

# build up IoTJob's timings
def build_job_timing(tim, t)
  # timing = TIMINGS[tim['type'].to_sym]
  params = tim['params']
  header = 'job.timings << '
  case tim['type']
  when 'interval'
    sec = params['interval_time'].to_i * 1000 # millisecond -> second
    case params['interval_time_unit']
    when 'hour'
      sec *= HOUR_SECONDS
    when 'minute'
      sec *= MINUTE_SECONDS
    end
    tab("#{header}IntervalTiming.new(#{sec})", t)

  when 'trigger'
    timing = []
    timing << tab('judges = []', t)
    params['triggers'].each {|trig|
      and_or = trig['and_or'] ? "and_or: :#{trig['and_or']}, " : ''
      judge = "type: :#{trig['param']}, value: #{trig['value']}, cond: :#{trig['cond']}"
      timing << tab("judges << {#{and_or}#{judge}}", t)
    }
    sec = params['trig_period'].to_i * 1000 # millisecond -> second
    case params['trig_peri_unit']
    when 'hour'
      sec *= HOUR_SECONDS
    when 'minute'
      sec *= MINUTE_SECONDS
    end
    timing << tab("#{header}TriggerTiming.new(job, #{sec}, judges, #{params['trig_off']})", t)

  when 'on_time'
    # TODO: implements
  when 'part_time'
    # TODO: implements
  end
end

# build up IoTJob's actions
def build_job_action(act, t)
  # action = ACTIONS[act['type'].to_sym]
  params = act['params']
  header = 'job.actions << '
  case act['type']
  when 'bluetooth'
    values = params.inject([]) {|ary, (k, v)|
      ary << ":#{k}" if v
    }
    tab("#{header}BluetoothAction.new(job, [#{values.join(', ')}])", t)
  when 'onoff'
    tab("#{header}OnOffAction.new(#{JOBS[params['jobid'].to_i].inspect}, #{params['onoff'].to_i != 0})", t)
  when 'gpio'
    # TODO: implements
  end
end

# build up IoTJobs
def build_job(job, t=0)
  JOBS[job['id']] = job['name']
  ja = []
  ja << tab("# #{job['name']}", t)
  ja << tab("JOBS << job = IoTJob.new(#{job['name'].inspect}, #{(job['onoff'] == 'on')})", t)
  job['sensor'].each {|sen|
    ja << build_job_sensor(sen, t)
  }
  job['timing'].each {|tim|
    ja << build_job_timing(tim, t)
  }
  job['action'].each {|act|
    ja << build_job_action(act, t)
  }
  ja.join("\n")
end

jobs = appcfg['jobList']
# jobs.each {|job|
#   puts "job: #{job['name']}"
# }
job_list = jobs.map() {|job|
  puts "job: #{job['name']}"
  build_job(job)
}.join("\n")

appscript = ERB.new(File.read(File.join($prjbase, 'app_edge.erb'))).result
app_edge_rb = File.join(prjdir, 'app_edge.rb')
File.write(app_edge_rb, appscript)
$logger.info "`#{app_edge_rb}` is written."

def hex2str(hex)
  str = ''
  (hex.size / 2).to_i.times {|i|
    str += hex[i*2, 2].to_i(16).chr
  }
  str
end

#
# Make app_bridge_init.rb
#
setting = appcfg['setting']
bt_setting = setting['bt_setting']
# Device name
devname = bt_setting['devname']
devname = nil if devname.nil? || devname.length == 0
# Proximity UUID
grpid = bt_setting['grpid'].gsub('-', '')
proximity = grpid.length == 32 ? hex2str(grpid) : nil
# Major / Minor
devid = bt_setting['devid']
devid = '000000' if devid.nil? || devid.length < 6
major = hex2str(devid[0, 2])
minor = hex2str(devid[2, 4])

appscript = ERB.new(File.read(File.join($prjbase, 'app_edge_init.erb'))).result
app_edge_init_rb = File.join(prjdir, 'app_edge_init.rb')
File.write(app_edge_init_rb, appscript)
$logger.info "`#{app_edge_init_rb}` is written."

#
# Make app_bridge.rb
#

devname = nil
# LoRa parameters
lora_setting = setting['lora_setting']
lora_deveui = lora_setting['deveui'].length == 16 ? hex2str(lora_setting['deveui']) : nil
lora_appeui = lora_setting['appeui'].length == 16 ? hex2str(lora_setting['appeui']) : nil
lora_appkey = lora_setting['appkey'].length == 32 ? hex2str(lora_setting['appkey']) : nil

appscript = ERB.new(File.read(File.join($prjbase, 'app_bridge.erb'))).result
# puts appscript if $DEBUG
app_bridge_rb = File.join(prjdir, 'app_bridge.rb')
File.write(app_bridge_rb, appscript)
$logger.info "`#{app_bridge_rb}` is written."

#
# Compile ruby scripts
#

platotool = File.join(platoroot, '.plato', 'tools')
mrbc141 = File.join(platotool, "mrbc141#{$exe}")
mrbc200 = File.join(platotool, "mrbc200#{$exe}")

`#{mrbc141} -E #{app_edge_rb}`
$logger.info "`#{app_edge_rb}` is compiled."

`#{mrbc141} -E #{app_edge_init_rb}`
$logger.info "`#{app_edge_init_rb}` is compiled."

`#{mrbc200} -E #{app_bridge_rb}`
$logger.info "`#{app_bridge_rb}` is compiled."


#
# Launch Visual Studio Code
#
code = "code"
if $platform == :mac
  if `which code`.chomp.size == 0
    code = "open -a /Applications/Visual\\ Studio\\ Code.app"
  end
end
`#{code} #{platoroot} #{app_edge_rb} #{app_edge_init_rb} #{app_bridge_rb}`
$logger.info 'VSCode launched.'


###############################
exit
###############################

# application type
# rapid:    'trigger' or 'server'
# advanced: TBD
app_type = cfg['app_type']

# target board
board = cfg['target_board']

# communication device
compara = cfg['com_para']
comcon = nil
btb = cfg['option_board'].inject(false) {|b,v| b |= (v['model'] == 'White-Tiger')} ? ' GPIO::BTB' : ''
case cfg['com_dev']
when 'BLE'
  comcls = 'PlatoDevice::RN4020'
  compara = nil
  comcon = nil
when 'ZigBee'
  comcls = 'PlatoDevice::XBee'
  compara = nil
  comcon = "@comdev.config#{btb}"
when 'WiFi'
  comcls = 'PlatoDevice::XBeeWiFi'
  compara = nil
  comcon = "@comdev.config#{btb}"
when 'Ethernet'
  comcls = 'PlatoDevice::Ethernet'
  compara = nil
  comcon = nil
else
  comcls = nil
  compara = nil
  comcon = nil
end
comdev = comcls ? "#{comcls}.open" : 'nil'

# sensing period [sec]
if sensing_period = cfg['sensing_period']
  sensing_period = sensing_period.to_i * 1000
end

# send period [min]
if send_period = cfg['send_period']
  send_period = send_period.to_i * 60 * 1000
end

# interval [sec]
if interval = action['interval']
  if sensing_period != 0
    interval = interval.to_f / (sensing_period.to_f / 1000.0)
  end
  interval = 1 if interval < 1
end

# trigger
if trigger = cfg['trigger']
  trigger = 'if' + trigger.inject([]) {|tri, t|
    # TODO: fix app.cfg key unmatch
    key = case t['key'][0,4]
    when 'tmp'; 'temp'
    when 'hum'; 'humi'
    when 'lx';  'illu'
    else;       t['key'][0,4]
    end
    # add trigger
    v = t['value']
    v = ((v.to_f - 32) * 5 / 9).round(3) if key == 'temp' && t['unit'] == 'F' # F->C
    tri << t['and_or'] << key << t['operator'] << v
  }.join(' ')
end

def time(t)
  return nil unless t
  tm = t.split(':')
  (tm[0].to_i * 10000 + tm[1].to_i * 100 + tm[2].to_i).to_s
end

if onetime = action['continuous']
  onetime = eval(onetime.downcase) ? nil : 'return nil if presig'
  if st = action['start']
    st = time(st)
  end
  if et = action['end']
    et = time(et)
  end
end

check_time_zone = nil
within_term = nil
if st || et
  check_time_zone = 'return false unless within_term?'
  within_term = <<"EOS"
  def within_term?
    t = @rtc.get_time
    now = t[3] * 10000 + t[4] * 100 + t[5]
    #{"return false if now<#{st}" if st}
    #{"return false if now>#{et}" if et}
    true
  end
EOS
end

# Make action script
server_uri = ''
case action['action_type']
when 'send_server'
  action_script = <<EOS
    # send to server
    @comdev.puts(values)
EOS
when 'ifttt'
  # server_uri
  server_uri = <<"EOS"
  SERVER_FQDN = 'maker.ifttt.com'
  URI = "/trigger/#{action['ifttt_event']}/with/key/#{action['ifttt_key']}"
EOS
  action['data_type'] = 'JSON'  # JSON data only
  protcol = (board == 'enzi') ? '' : "\'http\', "
  action_script = <<"EOS"
    # send to IFTTT service
    request = {'Content-Type'=>'Application/json'}
    request['Body'] = values
    begin
      ifttt = SimpleHttp.new(#{protcol}SERVER_FQDN, 80)
      ifttt.post(URI, request)
    rescue
    end
EOS
when 'blocks'
  # server_uri
  fqdn = "magellan-iot-#{action['blocks_entry']}-dot-#{action['blocks_prjid']}.appspot.com"
  blocks_addr = Resolv.getaddress(fqdn)
  server_uri = <<"EOS"
  SERVER_FQDN = '#{fqdn}'
  URI = '/'
  #{comcls}.setaddress(SERVER_FQDN, '#{blocks_addr}')
EOS
  # action
  action['blocks_msgtyp'] = action['blocks_msgtyp']
  json_s = <<"EOS"
{\\"api_token\\":\\"#{action['blocks_token']}\\",
\\"logs\\":[{
\\"type\\":\\"#{action['blocks_msgtyp']}\\",\\"attributes\\":
EOS
  json_s.gsub!("\n", '')
  json_e = '}]}'
  action['data_type'] = 'JSON'
  protcol = (board == 'enzi') ? '' : "\'http\', "
  action_script = <<"EOS"
    # send to MAGELLAN BLOCKS
    request = {'Content-Type'=>'Application/json'}
    request['Body'] = "#{json_s + '#{values}' + json_e}"
    begin
      blks = SimpleHttp.new(#{protocol}SERVER_FQDN, 80)
      blks.post(URI, request)
    rescue
    end
EOS
when 'gpio_out'
  action['data_type'] = 'NONE'  # data not use
  low = (action['gpio_value'].to_i == 0)
  action_script = <<"EOS"
    # write to GPIO port
    DigitalIO.new(GPIO::#{action['gpio_pin']}).write(edge == :positive ? GPIO::#{low ? "LOW" : "HIGH"} : GPIO::#{low ? "HIGH" : "LOW"})
EOS
else # 'free_text'
  if action_script = action['action_script']
    action_script = action_script.lines.map {|line|
      '    # ' + line
    }.join + "\n"
  end
end

# Make values
values = nil
items = []
case action['data_type']
when 'JSON'
  action['values'].each_with_index {|h, i|
    if action['action_type'].include?('ifttt')
      # IFTTT: "value1"〜"value3"
      key = "value#{i+1}"
    elsif action['action_type'].include?('blocks')
      # BLOCKS: "temperture"/"humidity"/"illuminance"
      key = h['title']
    else
      if key = h.values[0]
        key = key.gsub(/^@/, '').gsub('.', '_')[0,4]
      end
    end
    items << ('\"' + key + '\":' + '\"#{' + (app_type == 'trigger' ? h.values[0][0,4] : h.values[0]) + '}\"') if key
  }
  if action['action_type'].include?('blocks')
    devinfo = action['blocks_devinfo']
    devinfo = "@comdev.mac_address" if devinfo.size == 0
    items << "\\\"devinfo\\\":\\\"#{devinfo}\\\""
  end
  values = '"{' + items.join(',') + '}"'
when 'CSV'
  action['values'].each {|h|
    items << '#{' + (app_type == 'trigger' ? h.values[0][0,4] : h.values[0]) + '}'
  }
  values = '"' + items.join(',') + '"'
when 'NONE'
  values = "''"
end

# negative edge
negative_edge = ''
if action['gpio_not_occur'].to_i > 0
  negative_edge = "      app.action(v, :negative) if trigger == :negative\n"
end

# Write app.rb
appsrc = ERB.new(File.read(File.join($prjbase, app_type + '.erb'))).result
app = File.join(prjdir, 'app.rb')
File.write(app, appsrc)

# Launch Visual Studio Code
code = "code"
if $platform == :mac
  if `which code`.chomp.size == 0
    code = "open -a /Applications/Visual\\ Studio\\ Code.app"
  end
end
`#{code} #{platoroot} #{app}`

rescue => e
  $logger.error e
end
