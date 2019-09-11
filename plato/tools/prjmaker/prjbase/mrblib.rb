puts "+++ i2c.rb +++" if $DEBUG

#
# I2C class
#
class I2C
  # I2C#write_command(addr, cmd) => Fixnum
  # <params>
  #   addr:   slave address
  #   cmd:    Array of command and data to send
  # <return>
  #   result code.
  #     == 0  success
  #     != 0  error
  def write_command(addr, cmd)
    _write(addr, cmd, false)
  end

  # I2C#read_command(addr, cmd, len) => String
  # <params>
  #   addr:   slave address
  #   cmd:    Array of command and data to send
  #   len:    Maximum length for receive data
  # <return>
  #   Receive data (Binary string)
  #     nil   error
  def read_command(addr, cmd, len)
    ret = nil
    if _write(addr, cmd, true) == 0
      ret = _read(addr, len, true)
    end
    ret
  end
end
# UART class
class UART
  def initialize(nbuf=256)
    @buffer = '*' * nbuf
    @bufsize = nbuf
    @bufidx = 0
  end

  # # uart.gets(rs) #=> String
  # # <params>
  # #   rs:     Separator
  # # <return>
  # #   String: Read data (includs terminate separator)
  # def gets(rs="\n")
  #   s = ''
  #   while c = _read
  #     s += c
  #     break if c == rs
  #   end
  #   s
  # end

  # uart.get_line(rs) #=> String/nil
  # <params>
  #   rs:   Separator character
  # <return>
  #   String: Line data (exclude terminate separator)
  #   nil:    Cannot found separator

  # enable OP_RETURN_BLK ver.

  # def get_line(rs="\n")
  #   while @bufidx < @bufsize
  #     c = _read
  #     return nil if c == nil  # no data
  #     if c == rs
  #       line = @buffer[0, @bufidx]
  #       @bufidx = 0
  #       return line
  #     end
  #     @buffer[@bufidx] = c
  #     @bufidx += 1
  #   end
  #   # Not enough buffer size
  #   while c = _read
  #     if c == rs
  #       @bufidx = 0
  #       return @buffer
  #     end
  #     @buffer += c
  #   end
  #   nil
  # end

  # disable OP_RETURN_BLK ver.

  def get_line(rs="\n")
    line = nil
    while @bufidx < @bufsize
      c = _read
      break if c == nil
      if c == rs
        line = @buffer[0, @bufidx]
        @bufidx = 0
        break
      end
      @buffer[@bufidx] = c
      @bufidx += 1
    end
    return line if @bufidx < @bufsize

    # Not enough buffer size
    while c = _read
      if c == rs
        @bufidx = 0
        line = @buffer
        break
      end
      @buffer += c
      @bufsize += 1
    end
    # nil
    line
  end
end
class BLE
  def notify(type, *data)
    puts "notify(:#{type.to_s}, #{data})" if $DEBUG
    case type
      when :accel;    acceleration = *data    # = [x, y, z]
      when :gyro;     gyro = *data            # = [x ,y, z]
      when :geomag;   geomagnetic = *data     # = [x, y, z]
      when :temp;     temperature = data      # = temp
      when :humi;     humidity = data         # = humi
      when :airpres;  air_pressure = data     # = air_pres
      when :illum;    illuminance = data      # = illum
      when :gpsgga;   gps_gga = *data         # = [utc, lat, lng, hdr]
      when :gpsvtg;   gps_vtg = *data         # = [ttmg, mtmg, gsk, gskph]
      when :switch;   switch = data           # = swi
      when :vibra;    vibration = *data       # = [vibrate?, count]
      when :opcl;     open_close = *data      # = [open?, count]
      when :watlvl;   water_level = *data     # = [over?, count]
      when :battery;  battery = *data         # = [low?, level]
    end
  end
end
# distance.rb - Calculate distance between 2 points

EARTH_R = 6378137.0   # Equatorial radius
PI = 3.14159265359    # PI for mruby/c

# deg2rad(deg) #=> Float
# convert degrees to radians
# <params>
#   deg:  degrees
# <return>
#   radians
def deg2rad(deg)
  # deg.to_f * Math::PI / 180.0
  deg.to_f * PI / 180.0
end

# distance(lat1, lng1, lat2, lng2) => Float
# Calculate distance between 2 points
# <params>
#   lat1: Latitude #1
#   lng1: Longitude #1
#   lat2: Latitude #2
#   lng2: Longitude #2
# <return>
#   distance between 2 points.
def distance(lat1, lng1, lat2, lng2)
  lat1 = deg2rad(lat1)
  lng1 = deg2rad(lng1)
  lat2 = deg2rad(lat2)
  lng2 = deg2rad(lng2)

  lat_avr = (lat1 - lat2) / 2.0
  lng_avr = (lng1 - lng2) / 2.0

  EARTH_R * 2.0 * Math.asin(Math.sqrt(Math.sin(lat_avr) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(lng_avr) ** 2))
end

# puts distance(33.606316, 130.418108, 35.689608, 139.692080) # Fukuoka-Tokyo ≒ 879987.9929968589
# puts distance(33.606316, 130.418108, 43.064301, 141.346869) # Fukuoka-Sapporo ≒ 1418499.800039965
#
# constants
#
# GGA field index
GPS_GGA_TIME    = 1   # UTC time (HHMMSS.00)
GPS_GGA_LAT     = 2   # Latitude
GPS_GGA_NS      = 3   # 'N'orth / 'S'outh
GPS_GGA_LONG    = 4   # Longitude
GPS_GGA_EW      = 5   # 'E'ast / 'W'est
# GPS_GGA_QUELITY = 6   # Quality indicator for position fix
# GPS_GGA_NUMSV   = 7   # Number of satellites used
GPS_GGA_HDOP    = 8   # Horizontal Dilution of Precision
# GPS_GGA_ALT     = 9   # Altitude above mean sea level
# GPS_GGA_UALT    = 10  # Altitude units: meters
# GPS_GGA_SEP     = 11  # Geoid separation: difference between ellipsoid and mean sea level
# GPS_GGA_USEP    = 12  # Separation units: meters
# GPS_GGA_DIFFAGE = 13  # Age of differential corrections (blank when DGPS is not used)
# GPS_GGA_DIGGSTA = 14  # ID of station providing differential corrections (blank ion when DGPS is not used)
# GPS_GGA_CS      = 15  # Checksum

# VTG field index
GPS_VTG_COGT    = 1   # Course over ground
# GPS_VTG_T       = 2   # Fixed field: true 'T'
GPS_VTG_COGM    = 3   # Course over ground (magnetic). Only supported in ADR 4.10 and above.
# GPS_VTG_M       = 4   # Fixed field: magnetic 'M'
GPS_VTG_KNOTS   = 5   # Speed over ground
# GPS_VTG_N       = 6   # Fixed field: knots 'N'
GPS_VTG_KPH     = 7   # Speed over ground
# GPS_VTG_K       = 8   # Fixed field: kilometers per hour 'K'
# GPS_VTG_POSMODE = 9   # Mode Indicator, see position fix flags description NMEA v2.3 and above only
# GPS_VTG_CS      = 10  # Checksum

# # ZDA field index
# GPS_ZDA_TIME    = 1   # UTC Time (HHMMSS.00)
# GPS_ZDA_DAY     = 2   # UTC day (1-31)
# GPS_ZDA_MONTH   = 3   # UTC month (1-12)
# GPS_ZDA_YEAR    = 4   # UTC year
# GPS_ZDA_LTZH    = 5   # Local time zone hours (fixed to 00)
# GPS_ZDA_LTZN    = 6   # Local time zone minutes (fixed to 00)

# RMC field index
# GPS_RMC_URC     = 1   # UTC Time (HHMMSS.00)
# GPS_RMC_STATUS  = 2   # 'A'ctive / 'V'oid
# GPS_RMC_LAT     = 3   # Latitude
# GPS_RMC_NS      = 4   # 'N'orth / 'S'outh
# GPS_RMC_LONG    = 5   # Longitude
# GPS_RMC_EW      = 6   # 'E'ast / 'W'est
# GPS_RMC_KNOTS   = 7   # Speed over the ground in knots
# GPS_RMC_ANGLE   = 8   # Track angle in degrees True
GPS_RMC_DATE    = 9   # Date `DDMMYY`
# GPS_RMC_MAGVAR  = 10 # Magnetic Variation
# GPS_RMC_MAGEW   = 11 # Magnetic Variation 'E'ast / 'W'est

# # GGA floating values
# GPS_GGA_FLOATS = [
#   [:time,     GPS_GGA_TIME],
#   [:lat_raw,  GPS_GGA_LAT],
#   [:lng_raw,  GPS_GGA_LONG],
#   [:hdop,     GPS_GGA_HDOP]
# ]

# # VTG floating values
# GPS_VTG_FLOATS = [
#   [:ttmg,     GPS_VTG_COGT],
#   [:mtmg,     GPS_VTG_COGM],
#   [:gsk,      GPS_VTG_KNOTS],
#   [:gskph,    GPS_VTG_KPH]
# ]

# # ZDA values
# GPS_ZDA_FLOATS = [
#   [:time,     GPS_ZDA_TIME]
# ]
# GPS_ZDA_INTS = [
#   [:day,      GPS_ZDA_DAY],
#   [:month,    GPS_ZDA_MONTH],
#   [:year,     GPS_ZDA_YEAR],
#   [:ltzh,     GPS_ZDA_LTZH],
#   [:ltzn,     GPS_ZDA_LTZN]
# ]

# GPS class
class GPS
  # GPS.new #=> GPS
  def initialize
    @gga = {}
    @vtg = {}
    # @zda = {}
    @rmc = {}
    @inipos = {}
  end

  # gps.parse_floats(items, params) #=> Hash
  # <params>
  #   items:  GPS data list (Array of string)
  #   params: Parameters to parse (Array of [key, field_index])
  # <return>
  #   Hash    Floating values map
  def parse_floats(items, params)
    val = {}
    params.each {|pr|
      val[pr[0]] = items[pr[1]].to_f if items[pr[1]].length > 0
    }
    return val
  end

  # gps.parse_ints(items, params) #=> Hash
  # <params>
  #   items:  GPS data list (Array of string)
  #   params: Parameters to parse (Array of [key, field_index])
  # <return>
  #   Hash    Integer values map
  def parse_ints(items, params)
    val = {}
    params.each {|pr|
      val[pr[0]] = items[pr[1]].to_i if items[pr[1]].length > 0
    }
    return val
  end

  # gps.degree(f) #=> Float
  # <params>
  #   f:    Latitude/Longitude value (GNSS value)
  # <return>
  #   Float Latitude/Longitude (degrees)
  def degree(f)
    deg = (f / 100.0).to_i
    deg.to_f + (f - (deg * 100.0)) / 60.0
  end

  # gps.parse_line(line) #=> Hash
  def parse_line(line)
    return nil unless line

    # Dump raw data (for debug)
    # puts line

    # Split gps datas
    items = line.chomp.tr('*', ',').split(',')
    return nil if items == nil || items.size == 0 || items[0][0] != '$'

    val = {}
    case items[0][3, 3] #.upcase
    when 'GGA'  # $xxGGA
      val = parse_floats(items, [
              [:time,     GPS_GGA_TIME],
              [:lat_raw,  GPS_GGA_LAT],
              [:lng_raw,  GPS_GGA_LONG],
              [:hdop,     GPS_GGA_HDOP]
            ])
      val[:ns] = items[GPS_GGA_NS] if items[GPS_GGA_NS].length > 0
      val[:ew] = items[GPS_GGA_EW] if items[GPS_GGA_EW].length > 0
      # Latitude/Longitude change to degree
      if (val[:lat_raw])
        val[:lat] = degree(val[:lat_raw])
        val[:lat] = -val[:lat] if val[:ns] == 'S'  # South
      end
      if (val[:lng_raw])
        val[:lng] = degree(val[:lng_raw])
        val[:lng] = -val[:lng] if val[:ew] == 'W'  # West
      end
      @gga = val if val.size > 0
      puts "$xxGGA: #{@gga}" if $DEBUG && @gga && @gga.size > 0
      if !@inipos[:lat] && !@inipos[:lng] && val[:lat] && val[:lng]
        @inipos[:lat] = val[:lat]
        @inipos[:lng] = val[:lng]
        puts "Initiali position: lat=#{@inipos[:lat]}, lng=#{@inipos[:lng]}"
      end

    when 'VTG'  # $xxVTG
      val = parse_floats(items, [
              [:ttmg,   GPS_VTG_COGT],
              [:mtmg,   GPS_VTG_COGM],
              [:gsk,    GPS_VTG_KNOTS],
              [:gskph,  GPS_VTG_KPH]
            ])
      @vtg = val if val.size > 0
      puts "$xxVTG: #{@vtg}" if $DEBUG && @vtg && @vtg.size > 0

    # when 'ZDA'  # $xxZDA
    #   val = parse_floats(items, [[:time, GPS_ZDA_TIME]])
    #   val = val.merge(parse_ints(items, [
    #                     [:day,    GPS_ZDA_DAY],
    #                     [:month,  GPS_ZDA_MONTH],
    #                     [:year,   GPS_ZDA_YEAR],
    #                     [:ltzh,   GPS_ZDA_LTZH],
    #                     [:ltzn,   GPS_ZDA_LTZN]
    #                   ]))
    #   @zda = val if val.size > 0
    #   puts "$xxZDA: #{@zda}" if $DEBUG && @zda && @zda.size > 0
    # end

    when 'RMC'  # %xxRMC
      val = parse_ints(items, [[:date, GPS_RMC_DATE]])
      @rmc = val if val.size > 0
      puts "$xxRMC: #{rmc}" if $DEBUG && @rmc && @rmc.size > 0

    end
    return val
  end

  def gga; @gga; end  # Get GGA data
  def vtg; @vtg; end  # Get VTG data
  # def zda; @zda; end  # Get ZDA data
  def rmc; @rmc; end  # Get RMC data

  # gps.calc_distance(lat, lng) => Float/nil
  # Calculate from initial position
  # <params>
  #   lat:    Latitude of current position
  #   lng:    Longitude of current position
  # <return>
  #   Float:  Distance between initial and current position.
  #   nil:    Can't calculate.
  def calc_distance(lat, lng)
puts "gps.calc_distance"
    return nil unless @inipos[:lat] || @inipos[:lng]
    # calculate distance
    distance(@inipos[:lat], @inipos[:lng], lat, lng)
  end
end
# opt3001.rb
# OPT3001 - illuminance sensor

#
# OPT3001 class
#
class OPT3001
  SLAVE_ADDRESS_OPT = 0x44
  OPT_CMD_RESULT = 0x00
  OPT_CMD_CONFIG = 0x01

  def initialize
    @single = true
  end
  
  # レジスタアドレス0x01に16bit書き込むことで設定できる
  # 書き込むコマンドはリトルエンディアンの形で書き込む
  # 書き込むコマンドの各ビットが何を設定するかは以下の通りになる
  # bit15-12  スケールルクス範囲　どの範囲まで測定値を表示するか
  #           0x0000    40.95
  #           0x1000    81.90
  #           0x2000    163.80
  #           0x3000    327.60
  #           0x4000    655.20
  #           0x5000    1310.40
  #           0x6000    2620.80
  #           0x7000    5241.60
  #           0x8000    10483.20
  #           0x9000    20966.40
  #           0xA000    41932.80
  #           0xB000    83865.60
  #           0xC000    自動スケール設定モード　自動で範囲を決定する
  # bit11     変換プロセスの長さの設定 プロセスが長いほど精度は高くなる
  #           0 = 100ms
  #           1 = 800ms
  #           変換プロセスが100msの場合、スケールルクス範囲の設定により分解能が減少し、精度が落ちる
  #           スケールルクス範囲が0x50の場合1bit、0x40~0x10の場合2bit、0x00の場合3bit減少する
  # bit10-9   測定モードの設定
  #           0x0000  シャットダウン
  #           0x0200　シングルショット　一度測定すると電源が落ちる
  #           0x0400,0x0600　継続測定
  # bit4      割り込み通知メカニズムの制御
  #           0 結果、下限、上限でのみ割り込みを判断し、クリアイベントを発生させない
  #           1 クリアイベントが発生するまで割り込み報告メカニズムをラッチする
  # bit3      割り込み時のINTピンの状態の制御
  #           0 アクティブロー
  #           1 アクティブハイ
  # bit2      スケールルクス範囲を0xC0以外に設定し、このbitを立てるとRESULTレジスタの測定値の上位ビットを0x00にする
  # bit1-0    割り込み発生時のフォルトイベントの数
  #           0x0000の時1つ、0x0001の時2つ、0x0002の時3つ、0x0003の時４つ
  # 現在は暫定措置として決め打ちで以下のように設定している
  # bit15-12  0xC000  自動スケール設定
  # bit11     0       100ms
  # bit10-9   0x0200  シングルショット
  # bit4      1       クリアイベントが発生するまで割り込み報告メカニズムをラッチ
  # bit3      0       アクティブロー
  # bit2      0       設定しない
  # bit1-0    0x0000　1つ
  def setup
    I2C.write_command(SLAVE_ADDRESS_OPT, [OPT_CMD_CONFIG, 0xC2, 0x10])
  end

  # 照度の測定(単位:lux)
  # シングルショットの場合、はじめにsetupを呼び出す
  def read_lux
    if @single
      setup
    end
    I2C.write_command(SLAVE_ADDRESS_OPT, OPT_CMD_RESULT)
    opt = I2C.read_command(SLAVE_ADDRESS_OPT, OPT_CMD_RESULT, 2)
    return nil if !opt || opt.size < 2
    e = (opt[0].ord & 0xF0) >> 4
    h = (opt[0].ord & 0x0F) * 256 + opt[1].ord
    lux = (1 << e) * h / 100.0
    return lux
  end
end
# bma400.rb
# BMA400 - acceleration sensor

# constants
DEG = 180.0                 # Degrees per radian
PI = 3.141592653589793      # Math::PI
BMA_AXIS_SIZE       = 3     # BMA400 axis size
BMA_I2C_ADDR        = 0x14  # BMA400 I2C slave address
BMA_REG_ACC_X_LSB   = 0x04  # register for accelerometer data (LSB).
BMA_REG_INT_STAT0   = 0x0E  # register contain the interrupt status bits
BMA_REG_ACC_CONFIG0 = 0x19  # register contain the accelerometer configuration (0)
BMA_REG_ACC_CONFIG1 = 0x1A  # register contain the accelerometer configuration (1)
BMA_REG_INT_CONFIG0 = 0x1F  # register contains interrupt control bits (0)
BMA_REG_INT_CONFIG1 = 0x20  # register contains interrupt control bits (1)
BMA_INT_STAT0_DRDY  = 0x80  # data ready interrupt status bit

#
# BMA400 class
#
class BMA400
  # BMA400.new => BMA400
  def initialize
    @latest_accel = []
  end

  # BMA400.instance => BMA400
  # Get BMA400 instance
  def instance
    $_bma400 = BMA400.new unless $_bma400
    $_bma400
  end

  # setup sensor read acceleration
  # select sensor performance mode
  # write 8 bits for register address 0x1A, set configration
  # write 8 bits for register address 0x19, set performance mode
  # <params>  
  #   mode    :sleep      set sleep mode(0x00)
  #           :normal     set normal mode(0x01) (default)
  #           :low_power  set low power mode(0x02)
  # turn on data ready interrupt
  def setup(mode = :normal)
    # write command is like 0xXY
    # X:higher 4bit set data range(unit:g)、Y:lower 4bit set data rate(unit:Hz)
    # higher bit the following four types
    # 0x00 ±2
    # 0x40 ±4
    # 0x80 ±8
    # 0xC0 ±16
    # lower bit the following seven types
    # 0x05 12.5
    # 0x06 25
    # 0x07 50
    # 0x08 100
    # 0x09 200
    # 0x0A 400
    # 0x0B 800
    # TODO: Interim measures set range ±4g, data rate 12.5Hz
    I2C.write_command(BMA_I2C_ADDR, [BMA_REG_ACC_CONFIG1, 0x45])
    case mode
    when :sleep
      mode_cmd = 0x00
    when :low_power
      mode_cmd = 0x01
    when :normal
      mode_cmd = 0x02
    else
      mode_cmd = 0x02
    end
    I2C.write_command(BMA_I2C_ADDR, [BMA_REG_ACC_CONFIG0, mode_cmd])
    I2C.write_command(BMA_I2C_ADDR, [BMA_REG_INT_CONFIG0, BMA_INT_STAT0_DRDY])
    I2C.write_command(BMA_I2C_ADDR, [BMA_REG_INT_CONFIG1, BMA_INT_STAT0_DRDY])
  end

  # read acceleration value
  # whether or not data is being read is judged, and if it is read, reading is carried out
  # <params>　
  #   update     true       if it has not been updated, return empty array
  #              false      If it has not been updated, return previous value(default)
  def read_acceleration(update = false)
    interrupt = I2C.read_command(BMA_I2C_ADDR, BMA_REG_INT_STAT0, 1)
    # puts "sensor_measurement?: #{interrupt.ord.to_s(16)}" if $DEBUG
    return nil if !interrupt || interrupt.size < 1
    value = []
    if (interrupt.ord & BMA_INT_STAT0_DRDY) != 0 then
      accel_sb = I2C.read_command(BMA_I2C_ADDR, BMA_REG_ACC_X_LSB, 6)
      return nil if !accel_sb || accel_sb.size < 6
      BMA_AXIS_SIZE.times{|i|
        acc = accel_sb[i * 2 + 1].ord << 8 | accel_sb[i * 2].ord
        acc -= 4096 if acc >= 2048
        value[i] = acc / 512.0  # acc * 4.0 / 2048.0
      }
      @latest_accel = value
    else
      value = @latest_accel unless update
    end
    return value
  end
end
# shtc1.rb
# SHTC1/3 - temperature and humidity sensor

# constants
SHTC_I2C_ADDR = 0x70    # SHTC1/3 I2C slave address

#
# SHTC1 class
#
class SHTC1
  # SHTC1.instance => SHTC1
  # Get SHTC1 instance
  def instance
    $_shtc = SHTC1.new unless $_shtc
    $_shtc
  end

  # SHTC1#read_temperature => float
  # Read temperature (℃)
  # <params>
  #   none
  # <return>
  #   Float   temperature [℃]
  #   nil     read error
  def read_temperature
    # Wakeup
    # I2C.write_command(SHTC_I2C_ADDR, [0x35, 0x17])
    # sleep_ms(1) # wait for idle

    # Read (Temp. first)
    shtc = I2C.read_command(SHTC_I2C_ADDR, [0x7C, 0xA2], 2)
    return nil if !shtc || shtc.size < 2
    st = 256 * shtc[0].ord + shtc[1].ord
    temp = 175.0 * st / 65536.0 - 45.0

    # Sleep
    # I2C.write_command(SHTC_I2C_ADDR, [0xB0, 0x98])
    return temp
  end

  # SHTC1#read_humidity => Float
  # Read humidify (%)
  # <param>
  #   none
  # <return>
  #   Float   humidity [%]
  #   nil     read error
  def read_humidity
    # Wakeup
    # I2C.write_command(SHTC_I2C_ADDR, [0x35, 0x17])
    # sleep_ms(1) # wait for idle

    # Read (Humi. first)
    shtc = I2C.read_command(SHTC_I2C_ADDR, [0x5C, 0x24], 2)
    return nil if !shtc || shtc.size < 2
    sh = 256 * shtc[0].ord + shtc[1].ord
    hum = sh / 655.36 # sh / 65535.0 * 100.0

    # Sleep
    # I2C.write_command(SHTC_I2C_ADDR, [0xB0, 0x98])
    return hum
  end
end
# lps22hb.rb
# LPS22HB - air pressure sensor

# constants
LPS_I2C_ADDR            = 0x5c  # LPS22HB I2C slave address
LPS_CTRL_REG1           = 0x10  # CTRL REG.1
LPS_CTRL_REG2           = 0x11  # CTRL REG.2
LPS_READ                = 0x28  # Read value
LPS_CTRL_REG1_MASK_RATE = 0x70  # Data Rate mask pattern in CTRL REG.1
LPS_CTRL_REG2_ADD_INC   = 0x10  # Register address automatically increment
LPS_CTRL_REG2_ONESHOT   = 0x01  # Oneshot mode mask pattern in CTRL REG.2

#
# LPS22HB class
#
class LPS22HB
  # LPS22HB.new #=> LPS22HB
  def initialize
    @rate = nil
  end

  # LPS22HB.instance => LPS22HB
  # Get LPS22HB instannce
  def instance
    $_lps22h = LPS22HB.new unless $_lps22h
    $_lps22h
  end

  # lps22hb.data_rate = rate
  # <params>
  #   rate:   data rate
  #     :one_shot   One shot mode (default)
  #     :rate_10hz  1Hz
  #     :rate_10hz  10Hz
  #     :rate_25hz  25Hz
  #     :rate_50hz  50Hz
  #     :rate_75hz  75Hz
  def data_rate=(rate)
    # puts "LPS22HB#data_rate = #{rate}" if $DEBUG
    return true if @rate == rate  # Already set rate
    @rate = rate

    # read CTRL REG 1
    rs1 = I2C.read_command(LPS_I2C_ADDR, LPS_CTRL_REG1, 1)
    # puts "LPS22HB CTRL_REG1 = 0x#{rs1.ord.to_s(16)} (read)" if $DEBUG

    # os = 0x00 # disable one shot mode
    case rate.to_sym
      when :rate_1hz;   rt = 0x10   # 1Hz
      when :rate_10hz;  rt = 0x20   # 10Hz
      when :rate_25hz;  rt = 0x30   # 25Hz
      when :rate_50hz;  rt = 0x40   # 50Hz
      when :rate_75hz;  rt = 0x50   # 75Hz
      else                          # default (include :one_shot)
        rt = 0x00
        # os = LPS_CTRL_REG2_ONESHOT
        @rate = :one_shot
    end

    # write CTRL REG 1
    reg1 = rs1.ord & ~LPS_CTRL_REG1_MASK_RATE | rt
    # puts "LPS22HB CTRL_REG1 = 0x#{reg1.to_s(16)} (write)" if $DEBUG
    I2C.write_command(LPS_I2C_ADDR, [LPS_CTRL_REG1, reg1])
  end

  # lps22hb.read #=> Fixnum
  # Read air pressure sensing value (hPa)
  def read_air_pressure
    self.data_rate = :one_shot unless @rate

    # Enable one-shot acquire
    if @rate == :one_shot
      cfg2 = I2C.read_command(LPS_I2C_ADDR, LPS_CTRL_REG2, 1)
      if cfg2 && cfg2.length > 0
        I2C.write_command(LPS_I2C_ADDR, [LPS_CTRL_REG2, cfg2.ord | LPS_CTRL_REG2_ONESHOT | LPS_CTRL_REG2_ADD_INC])
      end
    end

    # Acquire air-pressure
    rs = I2C.read_command(LPS_I2C_ADDR, LPS_READ, 3)
    return nil if !rs || rs.size < 3
    raw = rs[2].ord << 16 | rs[1].ord << 8 | rs[0].ord
    # puts "LPS22HB READ 0x#{rs[0].ord.to_s(16)},0x#{rs[1].ord.to_s(16)},0x#{rs[2].ord.to_s(16)} => #{raw.to_f / 4096.0}" if $DEBUG
    return raw.to_f / 4096.0
  end

  # lps22hb.enable
  # Enable LPS22HB
  def enable
    self.data_rate = :one_shot  # One shot mode (need self in mruby/c)
    # puts "LPS22HB enabled" if $DEBUG
  end

  # lps22hb.disable
  # Disable LPS22HB
  def disable
    self.data_rate = :one_shot  # Power down (= one shot) mode (need self in mruby/c)
    # puts "LPS22HB disabled" if $DEBUG
  end
end
require './gps.rb' if __FILE__ == $0  # for UT

class RTL8771B < GPS
  # RTL8771B.new(uart) #=> RTL8771B
  # <params>
  #   uart:   Instance of UART
  def initialize(uart)
    # super # NOT WORK!!!
    # -- super --
    @gga = {}
    @vtg = {}
    @rmc = {}
    @inipos = {}
    # -- super --

    @uart = uart
  end

  # rtl.parse #=> nil
  def parse
    while line = @uart.get_line
      parse_line(line)
    end
  end
end

# for Ruby test
if __FILE__ == $0
  data = <<"EOS"
$GPGGA,123923.00,2446.79006,N,12059.72083,E,1,08,1.20,174.3,M,18.8,M,,*52
$GPGLL,2446.79006,N,12059.72083,E,123923.00,A,A*6C
$GPGSA,A,3,08,09,16,23,26,27,07,11,,,,,2.14,1.20,1.77,1*1B
$GPVTG,000.00,T,,M,000.027,N,000.050,K,A*3D
$GPGGA,123923.20,0823.34567,S,17821.98765,W,1,08,1.20,174.3,M,18.8,M,,*52
$GPZDA,201530.00,04,07,2002,00,00*60
$GPVTG,001.23,T,001.11,M,000.033,N,000.066,K,A*3D
$GPGGA,123923.40,1530.00000,S,12015.00000,W,1,09,1.21,174.4,M,18.9,M,,*52
EOS

  gps = RTL8771B.new(nil)
  gga = {}
  vtg = {}
  # zda = {}

  data.split("\n").each {|line|
    gps.parse_line(line)
    if gga != gps.gga
      puts "GGA: #{gga = gps.gga}"
    end
    if vtg != gps.vtg
      puts "VTG: #{vtg = gps.vtg}"
    end
    # if zda != gps.zda
    #   puts "ZDA: #{zda = gps.zda}"
    # end
  }
end # __FILE__
# sx1508b.rb
# SX1508B - Shifting GPO, LED Driver and Keypad engine

# constants
SX1508_I2C_ADDR = 0x20    # SX1508 I2C slave address

SX_LEDS       = 0b00001110  # LED1,2,3
MASK_SX_LEDS  = 0b11110001

#
# LED class
#
class SX1508B_LED
  def initialize(ion, ton=nil, off=nil, trise=nil, tfall=nil)
# puts "SX1508B_LED.new(#{ion}, #{ton}, #{off}, #{traise}, #{tfall}"
    @ion = ion      # RegIOnX
    @ton = ton      # RegTOnX
    @off = off      # RegOffX
    @trise = trise  # RegTRiseX
    @tfall = tfall  # RegTFallX
  end

  def on
    # puts "SX1508B_LED#on: @ion=#{@ion}"
    set(@ion, 0xff)
  end

  def off
    # puts "SX1508B_LED#off: @ion=#{@ion}"
    set(@ion, 0x00)
  end

  def pwm(val)
    # puts "SX1508B_LED#pwm(#{val}): @ion=#{@ion}"
    set(@ion, val)
  end

  # private
  def set(reg, val)
    I2C.write_command(SX1508_I2C_ADDR, [0x08, 0xff])
    I2C.write_command(SX1508_I2C_ADDR, [reg, val])
    I2C.write_command(SX1508_I2C_ADDR, [0x08, MASK_SX_LEDS])
  end
end

#
# SX1508B class
#
class SX1508B
  # SX1508B.instance => SX1508B
  # Get SX1508 instance
  def instance
    $_sx1508 = SX1508B.new unless $_sx1508
    $_sx1508
  end

  def initialize
    # puts "SX1508B.new"
    # create LEDs
    @led = {}
    @led[:green]  = SX1508B_LED.new(0x17)
    @led[:red]    = SX1508B_LED.new(0x19, 0x18, 0x1a)
    @led[:blue]   = SX1508B_LED.new(0x1c, 0x1b, 0x1d, 0x1e, 0x1f)
    # RegReset 1:0x12, 2:0x34
    I2C.write_command(SX1508_I2C_ADDR, [0x7d, 0x12])
    I2C.write_command(SX1508_I2C_ADDR, [0x7d, 0x34])
    # RegInputDisable
    I2C.write_command(SX1508_I2C_ADDR, [0x00, SX_LEDS])
    # RegPullUp
    I2C.write_command(SX1508_I2C_ADDR, [0x03, 0x00])
    # RegOpenDrain
    I2C.write_command(SX1508_I2C_ADDR, [0x05, SX_LEDS])
    # RegDir
    I2C.write_command(SX1508_I2C_ADDR, [0x07, MASK_SX_LEDS])
    # RegClock
    I2C.write_command(SX1508_I2C_ADDR, [0x0f, 0x40])    # b6:5=0b10
    # RegMisc
    I2C.write_command(SX1508_I2C_ADDR, [0x10, 0x1c])    # b6:4=0b001, b3=1, b1=1
    # RegLEDDriverEnable
    I2C.write_command(SX1508_I2C_ADDR, [0x11, SX_LEDS]) # b6:4=0b001, b3=1, b1=1
    # RegIOn1..3
    I2C.write_command(SX1508_I2C_ADDR, [0x17, 0x00])    # LED1(green) off
    I2C.write_command(SX1508_I2C_ADDR, [0x19, 0x00])    # LED2(red) off
    I2C.write_command(SX1508_I2C_ADDR, [0x1c, 0x00])    # LED3(blue) off
    # RegData
    I2C.write_command(SX1508_I2C_ADDR, [0x08, MASK_SX_LEDS])
  end

  def led(color)
    @led[color]
  end
end
class Battery
  def instance
    $_bat = Battery.new unless $_bat
    $_bat
  end
end
