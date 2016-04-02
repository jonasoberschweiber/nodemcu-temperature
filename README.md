# NodeMCU temperature sensor

`init.lua` contains the code to read the temperature of two connected DS18B20 sensors every 10 seconds and send them to the Librato proxy written in Go. The proxy can be found in `proxy.go`. A `dev` firmware with `http`, `ow` and `crypto` is needed to run the code.

More details can be found [here][1].

[1]: http://oberschweiber.com/2016/04/02/nodemcu-temperature.html
