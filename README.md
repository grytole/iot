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
  * `mv SRC DEST` - renames file (rewrite of existing file is forbidden)
  * `cp SRC DEST` - creates a copy of file (rewrite of existing file is forbidden)
  * `rm FILENAME` - removes file
  * `whoami` - shows device params (ip settings, MAC address, NodeMCU version, chip id, flash size)
  * `lswifi` - lists available Wi-Fi access points
  * `wifi SSID PASS` - connects to access point (it will brake Telnet connection)
  * `reboot` - reboots device
