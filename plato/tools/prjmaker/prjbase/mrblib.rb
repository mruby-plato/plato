puts "+++ i2c.rb +++" if $DEBUG

class I2C
  def write_command(addr, cmd)
    _write(addr, cmd)
  end

  def read_command(addr, cmd, len)
    _write(addr, cmd)
    _read(addr, len)
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
  def get_line(rs="\n")
    while @bufidx < @bufsize
      c = _read
      return nil if c == nil  # no data
      if c == rs
        line = @buffer[0, @bufidx]
        @bufidx = 0
        return line
      end
      @buffer[@bufidx] = c
      @bufidx += 1
    end
    # Not enough buffer size
    while c = _read
      if c == rs
        @bufidx = 0
        return @buffer
      end
      @buffer += c
    end
    nil
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
end
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
    e = (opt[0].ord & 0xF0) >> 4
    h = (opt[0].ord & 0x0F) * 256 + opt[1].ord
    lux = (1 << e) * h / 100.0
    return lux
  end
end
DEG = 180.0
PI = 3.141592654                    # math PI num
AXIS_SIZE = 3                       # use sensor's axis size

class BMA400
  SLAVE_ADDRESS_BMA = 0x14    # BMA400 slave address
  CMD_ACC_X_LSB     = 0x04    # register in measured value　call 6 bytes from here when reading
  CMD_ACC_CONFIG0   = 0x19    # register for set performance mode
  CMD_ACC_CONFIG1   = 0x1A    # register for set data range and data rate
  CMD_INT_CONFIG0   = 0x1F    # register for set of interrupt control type
  CMD_INT_CONFIG1   = 0x20    # register for set interrupt control mode
  CMD_INT_STAT0     = 0x0E    # register for write bits whether an interrupt has occurred
  INT_DATA_READY    = 0x80    # value for when interrupt occurred

  def initialize
    @save_accel = []               # 加速度の保存値
  end

  # setup sensor read acceleration
  # select sensor performance mode
  # write 8 bits for register address　0x1A, set configration
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
    I2C.write_command(SLAVE_ADDRESS_BMA, [CMD_ACC_CONFIG1, 0x45])
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
    I2C.write_command(SLAVE_ADDRESS_BMA, [CMD_ACC_CONFIG0, mode_cmd])
    I2C.write_command(SLAVE_ADDRESS_BMA, [CMD_INT_CONFIG0, INT_DATA_READY])
    I2C.write_command(SLAVE_ADDRESS_BMA, [CMD_INT_CONFIG1, INT_DATA_READY])
  end

  # read acceleration value
  # whether or not data is being read is judged, and if it is read, reading is carried out
  # <params>　
  #   update     true       if it has not been updated, return empty array
  #              false      If it has not been updated, return previous value(default)
  def read_acceleration(update = false)
    interrupt = I2C.read_command(SLAVE_ADDRESS_BMA, CMD_INT_STAT0, 1)
    # puts "sensor_measurement?: #{interrupt.ord.to_s(16)}" if $DEBUG
    value = []
    if (interrupt.ord & INT_DATA_READY) != 0 then
      accel_sb = I2C.read_command(SLAVE_ADDRESS_BMA, CMD_ACC_X_LSB, 6)
      AXIS_SIZE.times{|i|
        value[i] = 256 * accel_sb[2 * i + 1].ord + accel_sb[2 * i].ord
        value[i] -= 4096 if value[i] >= 2048
        value[i] = value[i] * 4.0 / 2048.0
      }
      @save_accel = value
    else
      value = @save_accel unless update
    end
    return value
  end
end
class SHTC1
  SLAVE_ADDRESS_SHTC = 0x70
  READ_CMD_SHTC = 0x71
  SENSOR = SHTC1.new
  def instance
    return SENSOR
  end
  # 温度の取得
  # クロックストレッチングありで測定
  # クロックストレッチングがありの場合、 センサ側が送信する時、処理時間の確保のためマスタ側を待たせることがある
  def read_temperature
    I2C.write_command(SLAVE_ADDRESS_SHTC, [0x7C, 0xA2])
    shtc = I2C.read_command(SLAVE_ADDRESS_SHTC, READ_CMD_SHTC, 2)
    st = 256 * shtc[0].ord + shtc[1].ord
    temp = 175.0 * st / 65536.0 - 45.0
    return temp
  end

  # 湿度の取得
  # クロックストレッチングのありで測定
  def read_humidity
    I2C.write_command(SLAVE_ADDRESS_SHTC, [0x5C, 0x24])
    shtc = I2C.read_command(SLAVE_ADDRESS_SHTC, READ_CMD_SHTC, 2)
    sh = 256 * shtc[0].ord + shtc[1].ord
    hum = 100 * sh / 65536.0
    return hum
  end
end
# LPS22HB (Air pressure sensor) class
class LPS22HB
  SLAVE_ADDR_LPS22HB      = 0x5c
  LPS_CTRL_REG1           = 0x10  # CTRL REG.1
  LPS_CTRL_REG2           = 0x11  # CTRL REG.2
  LPS_READ                = 0x28  # Read value
  LPS_CTRL_REG1_MASK_RATE = 0x70  # Data Rate mask pattern in CTRL REG.1
  LPS_CTRL_REG2_ONESHOT   = 0x01  # Oneshot mode mask pattern in CTRL REG.2

  # LPS22HB.new #=> LPS22HB
  def initialize
    @rate = nil
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

    # read CTRL REG 1/2
    rs1 = I2C.read_command(SLAVE_ADDR_LPS22HB, LPS_CTRL_REG1, 1)
    rs2 = I2C.read_command(SLAVE_ADDR_LPS22HB, LPS_CTRL_REG2, 1)
    # puts "LPS22HB CTRL_REG1/2 = 0x#{rs1.ord.to_s(16)},0x#{rs2.ord.to_s(16)} (read)" if $DEBUG

    os = 0x00 # disable one shot mode
    case rate.to_sym
      when :rate_1hz;   rt = 0x10   # 1Hz
      when :rate_10hz;  rt = 0x20   # 10Hz
      when :rate_25hz;  rt = 0x30   # 25Hz
      when :rate_50hz;  rt = 0x40   # 50Hz
      when :rate_75hz;  rt = 0x50   # 75Hz
      else                          # default (include :one_shot)
        rt = 0x00
        os = LPS_CTRL_REG2_ONESHOT
        @rate = :one_shot
    end

    # write CTRL REG 1/2
    reg1 = rs1.ord & ~LPS_CTRL_REG1_MASK_RATE | rt
    reg2 = rs2.ord & ~LPS_CTRL_REG2_ONESHOT | os
    # puts "LPS22HB CTRL_REG1/2 = 0x#{reg1.to_s(16)},0x#{reg2.to_s(16)} (read)" if $DEBUG
    I2C.write_command(SLAVE_ADDR_LPS22HB, [LPS_CTRL_REG1, reg1])
    I2C.write_command(SLAVE_ADDR_LPS22HB, [LPS_CTRL_REG2, reg2])

    # # verify CTRL REG 1/2
    # if $DEBUG
    #   rs1 = I2C.read_command(SLAVE_ADDR_LPS22HB, LPS_CTRL_REG1, 1)
    #   rs2 = I2C.read_command(SLAVE_ADDR_LPS22HB, LPS_CTRL_REG2, 1)
    #   puts "LPS22HB CTRL_REG1 verify 0x#{rs1.ord.to_s(16)} (#{reg1 == rs1.ord ? 'OK' : 'NG'})"
    #   puts "LPS22HB CTRL_REG2 verify 0x#{rs2.ord.to_s(16)} (#{reg2 == rs2.ord ? 'OK' : 'NG'})"
    # end
  end

  # lps22hb.read #=> Fixnum
  # Read air pressure sensing value (hPa)
  def read_air_pressure
    rs = I2C.read_command(SLAVE_ADDR_LPS22HB, LPS_READ, 3)
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
    # super
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
