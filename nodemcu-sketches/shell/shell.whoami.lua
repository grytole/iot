-- whoami
return function()
  local ipaddr, netmask, gateway = wifi.sta.getip()
  local majorver, minorver, devver, chipid, _, flashsize, _, _ = node.info()
  coroutine.yield( "IP address  : " .. ipaddr .. "\n" )
  coroutine.yield( "Netmask     : " .. netmask .. "\n" )
  coroutine.yield( "Gateway     : " .. gateway .. "\n" )
  coroutine.yield( "MAC address : " .. wifi.sta.getmac() .. "\n" )
  coroutine.yield( "Host name   : " .. wifi.sta.gethostname() .. "\n" )
  coroutine.yield( string.format( "NodeMCU     : %s.%s.%s\n", majorver, minorver, devver ) )
  coroutine.yield( "Chip ID     : " .. chipid .. "\n" )
  coroutine.yield( "Flash size  : " .. flashsize .. " kB\n" )
end
