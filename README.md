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
  * `ls` - lists files stored on flash with their size
  * `df` - provides summary for file system
  * `cat FILENAME` - prints contents of file FILENAME
  * `head FILENAME [NUMLINES]` - prints first NUMLINES lines (default is 10) of file FILENAME
  * `tail FILENAME [NUMLINES]` - prints last NUMLINES lines (default is 10) of file FILENAME
  * `mv SRC DEST` - renames file SRC to DEST (rewrite of existing file is forbidden)
  * `cp SRC DEST` - creates a copy of file SRC as DEST (rewrite of existing file is forbidden)
  * `rm FILENAME` - removes file FILENAME
  * `grep REGEXP [FILENAME]` - searches lua-style REGEXP pattern in file FILENAME (FILENAME supports wildcards and defaults to `*`)
  * `whoami` - shows device params (ip settings, MAC address, NodeMCU version, chip id, flash size)
  * `iw CMD [ARG1 [ARG2]]` - Wi-Fi tool. 'scan' as CMD starts AP search (`iw scan`). 'connect' as CMD tries to connect to AP (`iw connect ssid password`).
  * `luac FILENAME` - compiles `.lua` source file into `.lc` file
  * `reboot` - reboots device
  * `ed [FILENAME]` - ed text editor ( `Q<return>` to leave :) - get a cheatsheet if you don't know it good enough )

Tips:
  * port is default for Telnet server: 23
  * number in the prompt shows available heap
  * server is written with coroutines - it is the only working way for me to eliminate nasty memory leak with server example from docs
  * use only needed plugins - now it has one file for one command and you can see all supported commands by `ls` (if you have ls plugin installed)

#### Wget module - HTTP/HTTPS file downloader
```
dofile("wget.lua").wget("https://example.com/path/target.file")
dofile("wget.lua").wget("https://example.com/path/target.file", "dest.file")
```
