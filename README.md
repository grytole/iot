### Nodemcu sketches

- GY-68 module - BMP180 sensor
```
dofile("bmp180.lua").help()
bmp = dofile("bmp180.lua")
isok = bmp.init(sda, scl, oss)
{temp, pa, hgmm, alt} = bmp.read()
```

- GY-273 module - HMC5883L sensor
```
dofile("hmc5883l.lua").help()
hmc = dofile("hmc5883l.lua")
isok = hmc.init(sda, scl)
{x, y, z} = hmc.read()
```

- Trigonometry module - software realization of basic functions
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
