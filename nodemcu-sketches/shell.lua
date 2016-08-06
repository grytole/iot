do
  local prompt = function()
    local heap = string.format( "%05s", node.heap() )
    return string.char( 27 ) .. "[31m" .. heap .." $" .. string.char( 27 ) .. "[0m "
  end

  local ls = function()
    for name, size in pairs( file.list() ) do
      coroutine.yield( string.format( "%7d %s\n", size, name ) )
    end
    local _, used, left = file.fsinfo()
    coroutine.yield( string.format( "\n%7d used\n%7d left\n", used, left ) )
  end

  local cat = function( filename )
    local filename = filename or ""
    if not file.exists( filename ) then
      coroutine.yield( string.format( "file '%s' does not exist\n", filename ) )
    else
      local done = false
      file.open( filename, "r" )
      while not done do
        local line = file.readline()
        if line then
          coroutine.yield( line )
        else
          done = true
        end
      end
      file.close()
    end
  end

  local mv = function( src, dst )
    local src = src or ""
    local dst = dst or ""
    local src_exists = file.exists( src )
    local dst_exists = file.exists( dst )
    if not src_exists then
      coroutine.yield( string.format( "source file '%s' does not exist\n", src ) )
    elseif dst_exists then
      coroutine.yield( string.format( "destination file '%s' already exists\n", dst ) )
    else
      file.rename( src, dst )
    end
  end

  local cp = function( src, dst )
    local src = src or ""
    local dst = dst or ""
    local src_exists = file.exists( src )
    local dst_exists = file.exists( dst )
    if not src_exists then
      coroutine.yield( string.format( "source file '%s' does not exist\n", src ) )
    elseif dst_exists then
      coroutine.yield( string.format( "destination file '%s' already exists\n", dst ) )
    else
      local buf, done = {}, false
      file.open( src, "r" )
      while not done do
        local line = file.readline()
        if line then
          table.insert( buf, line )
        else
          done = true
        end
      end
      file.close()
      file.open( dst, "w" )
      while #buf do
        file.write( table.remove( buf, 1 ) )
      end
      file.close()
    end
  end

  local rm = function( filename )
    local filename = filename or ""
    if not file.exists( filename ) then
      coroutine.yield( string.format( "file '%s' does not exist\n", filename ) )
    else
      file.remove( filename )
    end
  end

  local whoami = function()
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

  local lswifi = function()
    local result, done = {}, false
    local listap = function( t )
      table.insert( result, "\n" )
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      table.insert( result, ":                             SSID :             BSSID : RSSI :     AUTH : CH :\n" )
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      for bssid, v in pairs( t ) do
        local ssid, rssi, auth, channel = string.match( v, "([^,]+),([^,]+),([^,]+),([^,]*)" )
        if auth == "1" then
          auth = "open"
        elseif auth == "2" then
          auth = "wpa"
        elseif auth == "3" then
          auth = "wpa2"
        elseif auth == "4" then
          auth = "wpa_wpa2"
        end
        table.insert( result, string.format( ": %32s : %17s : %4s : %8s : %2s :\n", ssid, bssid, rssi, auth, channel ) )
      end
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      done = true
    end

    coroutine.yield( "Scanning" )
    wifi.sta.getap( 1, listap )
    while not done do
      coroutine.yield( " ." )
    end
    while #result do
      coroutine.yield( table.remove( result, 1 ) )
    end
  end

  local wifi = function( ssid, password )
    if not ssid then
      coroutine.yield( "SSID should be specified\n" )
    else
      wifi.setmode( wifi.STATION )
      wifi.sta.config( ssid, password )
    end
  end

  local reboot = function()
    node.restart()
  end

  local shell = function( cmdline )
    local argv = {}
    for arg in cmdline:gmatch( "%S+" ) do
      table.insert( argv, arg )
    end
    if argv[ 1 ] == "ls" then
      ls()
    elseif argv[ 1 ] == "cat" then
      cat( argv[ 2 ] )
    elseif argv[ 1 ] == "mv" then
      mv( argv[ 2 ], argv[ 3 ] )
    elseif argv[ 1 ] == "cp" then
      cp( argv[ 2 ], argv[ 3 ] )
    elseif argv[ 1 ] == "rm" then
      rm( argv[ 2 ] )
    elseif argv[ 1 ] == "whoami" then
      whoami()
    elseif argv[ 1 ] == "lswifi" then
      lswifi()
    elseif argv[ 1 ] == "wifi" then
      wifi( argv[ 2 ], argv[ 3 ] )
    elseif argv[ 1 ] == "reboot" then
      reboot()
    end
  end

  shell_server = net.createServer( net.TCP, 180 )
  shell_server:listen( 23, function( lc )
    local cmd, ongoing = {}, false
    lc:on( "receive", function( rc, payload )
      if string.byte( payload ) ~= 255 and not ongoing then
        if string.byte( payload ) ~= 13 then
          table.insert( cmd, payload )
        else
          ongoing = true
          local co = coroutine.create( shell )
          local respond = function( sc, req )
            local state, str = coroutine.resume( co, req )
            if state and str then
              sc:send( str )
            elseif ongoing then
              sc:send( prompt() )
              ongoing = false
            end
          end
          rc:on( "sent", respond )
          local request = table.concat( cmd )
          cmd = {}
          respond( rc, request )
        end
      end
    end )
    lc:send( prompt() )
  end )
end
