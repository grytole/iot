-- shell
do
  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local prompt = function()
    local heap = string.format( "%05s", node.heap() )
    return esc( "g" ) .. heap .." $ " .. esc()
  end

  local shellfunc = function( cmdline )
    local argv = {}
    for arg in cmdline:gmatch( "%S+" ) do
      table.insert( argv, arg )
    end
    if not argv[ 1 ] then
      return
    else
      local luaplugin = "shell." .. argv[ 1 ] .. ".lua"
      local lcplugin = "shell." .. argv[ 1 ] .. ".lc"
      if file.exists( lcplugin ) then
        dofile( lcplugin )( argv[ 2 ], argv[ 3 ], argv[ 4 ] )
      elseif file.exists( luaplugin ) then
        dofile( luaplugin )( argv[ 2 ], argv[ 3 ], argv[ 4 ] )
      else
        coroutine.yield( "Unknown command\n" )
      end
    end
  end

  shell = net.createServer( net.TCP, 600 )
  shell:listen( 23, function( lc )
    local cmd, ongoing, thread = {}, false, nil
    local respond = function( sc, req )
      local state, str = coroutine.resume( thread, req )
      if state and str then
        sc:send( str )
      elseif ongoing then
        sc:send( prompt() )
        ongoing = false
      end
    end
    lc:on( "receive", function( rc, payload )
      if string.byte( payload ) ~= 255 then
        if string.byte( payload ) ~= 13 then
          table.insert( cmd, payload )
        else
          local request = table.concat( cmd )
          cmd = {}
          if not ongoing then
            ongoing = true
            thread = coroutine.create( shellfunc )
          end
          rc:on( "sent", respond )
          respond( rc, request )
        end
      end
    end )
    lc:send( prompt() )
  end )
end
