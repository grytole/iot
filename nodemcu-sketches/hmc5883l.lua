------------------------------------------------------------------------------
-- HMC5883L query module
--
-- dofile("hmc5883l.lua").help()
--
-- hmc = dofile("hmc5883l.lua")
-- isok = hmc.init(sda, scl)
-- {x, y, z} = hmc.read()
------------------------------------------------------------------------------
local M
do
  -- cache
  local i2c, print = i2c, print

  -- helpers
  local r8 = function(reg)
    i2c.start(0)
    i2c.address(0, 0x1E, i2c.TRANSMITTER)
    i2c.write(0, reg)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, 0x1E, i2c.RECEIVER)
    local r = i2c.read(0, 1)
    i2c.stop(0)
    return r:byte(1)
  end

  local w8 = function(reg, val)
    i2c.start(0)
    i2c.address(0, 0x1E, i2c.TRANSMITTER)
    i2c.write(0, reg)
    i2c.write(0, val)
    i2c.stop(0)
  end

  local r16u = function(reg)
    return r8(reg) * 256 + r8(reg + 1)
  end

  local r16 = function(reg)
    local r = r16u(reg)
    if r > 32767 then r = r - 65536 end
    return r
  end

  -- gain
  local gain = 0x20

  -- hmc.help
  local help = function()
    print("HMC5883L query module")
    print("  dofile(\"hmc5883l.lua\").help()")
    print("  hmc = dofile(\"hmc5883l.lua\")")
    print("  isok = hmc.init(sda, scl)")
    print("  {x, y, z} = hmc.read()")
  end

  -- hmc.init
  local init = function(sda, scl)
    i2c.setup(0, sda, scl, i2c.SLOW)
    -- check id
    if r8(0x0A) == 0x48 and r8(0x0B) == 0x34 and r8(0x0C) == 0x33 then
      -- data output rate and samples num = 1sample @ 75Hz
      w8(0x00, 0x18)
      -- device gain = 0.92mG/LSb
      w8(0x01, gain)
      -- operating mode = continious
      w8(0x02, 0x00)
      return true
    else
      return false
    end
  end

  -- hmc.read
  local read = function()
    -- Gausses
    local result = {}
    if gain == 0x20 then
      result.x = r16(0x03) * 0.92
      result.y = r16(0x07) * 0.92
      result.z = r16(0x05) * 0.92
    end
    return result
  end

  -- expose
  M = {
    help = help,
    init = init,
    read = read,
  }
end
return M