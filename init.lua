-- 18b20 Example
sensor1_pin = 1
sensor1_name = "mcu1.temp1"
sensor2_pin = 3
sensor2_name = "mcu1.temp2"
proxy_ip = ""
proxy_port = ""
hmac_key = ""
ntp_ip = "141.30.228.4"
wifi_name = ""
wifi_password = ""

function readtemp(pin)
  ow.setup(pin)
  count = 0
  repeat
    count = count + 1
    addr = ow.reset_search(pin)
    addr = ow.search(pin)
    tmr.wdclr()
  until (addr ~= nil) or (count >= 100)
  if addr == nil then
    print("No devices found")
    return "-250.00"
  else
    crc = ow.crc8(string.sub(addr, 1, 7))
    if crc == addr:byte(8) then
      if (addr:byte(1) == 0x10) or (addr:byte(1) == 0x28) then
        ow.reset(pin)
        ow.select(pin, addr)
        -- Initiate measurement
        ow.write(pin, 0x44, 1)
        tmr.delay(1000000)
        present = ow.reset(pin)
        ow.select(pin, addr)
        -- Read memory
        ow.write(pin, 0xBE, 1)
        data = nil
        data = string.char(ow.read(pin))
        for i = 1, 8 do
          data = data .. string.char(ow.read(pin))
        end
        crc = ow.crc8(string.sub(data, 1, 8))
        if crc == data:byte(9) then
          t = (data:byte(1) + data:byte(2) * 256) * 625
          t1 = t / 10000
          t2 = t % 10000
          return t1 .. "." .. t2
        end
        tmr.wdclr()
      else
        print("Device not recognized")
      end
    else
      print("Invalid CRC")
    end
  end
end

function sendtemp()
  print("Connecting")
  count = 0
  tmr.alarm(1, 500, 1, function()
    if wifi.sta.getip() ~= nil then
      print("Connected")
      sntp.sync(ntp_ip,
        function(sec, usec, server)
            print("sync", sec, usec, server)

            temp1 = readtemp(sensor1_pin)
            temp2 = readtemp(sensor2_pin)
            
            body = "gauges[0][name]=" ..
                sensor1_name ..
                "&gauges[0][value]=" ..
                temp1 ..
                "&gauges[1][name]=" ..
                sensor2_name ..
                "&gauges[1][value]=" ..
                temp2
            auth = encoder.toHex(crypto.hmac("sha256", sec .. "|" .. body, hmac_key))
            url = "http://" .. proxy_ip .. ":" .. proxy_port .. "/?tstamp=" .. sec .. "&auth=" .. auth
            http.post(url, "Content-Type: text/plain\r\n", body, function(code, data)
                print(code, data)
            end)
        end,
        function()
            print("failed!")
        end)
      tmr.stop(1)
    else
      count = count + 1
      if count >= 40 then -- 20 seconds
        print("No IP")
        tmr.stop(1)
      end
    end
  end)
end

wifi.setmode(wifi.STATION)
wifi.sta.config(wifi_name, wifi_password)

tmr.alarm(0, 10 * 1000, tmr.ALARM_AUTO, sendtemp)
--sendtemp()
