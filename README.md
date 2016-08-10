### Nodemcu sketches

#### GY-68 module - BMP180 sensor
```
dofile("bmp180.lua").help()
bmp = dofile("bmp180.lua")
isok = bmp.init(sda, scl, oss)
{temp, pa, hgmm, alt} = bmp.read()
```

#### GY-273 module - HMC5883L sensor
```
dofile("hmc5883l.lua").help()
hmc = dofile("hmc5883l.lua")
isok = hmc.init(sda, scl)
{x, y, z} = hmc.read()
```

#### Trigonometry module - software realization of basic functions
```
tg = dofile("trigonometry.lua")
val = tg.tan(rad)
val = tg.sin(rad)
val = tg.cos(rad)
rad = tg.atan(x)
rad = tg.atan2(y, x)
rad = tg.asin(x)
rad = tg.acos(x)
deg = tg.deg(rad)
rad = tg.rad(deg)
pi = tg.pi
```

#### Shell module - simple command-line interface via Telnet connection
```
dofile("shell.lua")
```
Supported commands:
  * `ls` - lists files stored on flash with their size, also provides summary for file system
  * `cat FILENAME` - prints contents of file
  * `head FILENAME` - prints first 10 lines of file
  * `tail FILENAME` - prints last 10 lines of file
  * `mv SRC DEST` - renames file (rewrite of existing file is forbidden)
  * `cp SRC DEST` - creates a copy of file (rewrite of existing file is forbidden)
  * `rm FILENAME` - removes file
  * `grep REGEXP [FILENAME]` - searches lua-style regexp pattern in file (supports wildcards and defaults to `*`)
  * `whoami` - shows device params (ip settings, MAC address, NodeMCU version, chip id, flash size)
  * `lswifi` - lists available Wi-Fi access points
  * `wifi SSID PASS` - connects to access point (it will brake Telnet connection)
  * `reboot` - reboots device

Tips:
  * port is default for Telnet server: 23
  * number in the prompt shows available heap
  * server is written with coroutines - it is the only working way for me to eliminate nasty memory leak with server example from docs

#### Wget module - HTTP/HTTPS file downloader
```
dofile("wget.lua").wget("https://example.com/path/target.file")
dofile("wget.lua").wget("https://example.com/path/target.file", "dest.file")
```
