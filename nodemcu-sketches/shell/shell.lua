-- shell
do
  local auth = {
    authenticated = false,
    username = "",
    userlist = {},
  }

  local readpassfile = function()
    if file.exists( "passwd" ) then
      local done, size = false, 0
      file.open( "passwd", "r" )
      while not done do
        local line = file.readline()
        if line then
          local u, p = string.match( line, "^([^%c:]+):(%w+)" )
          if u and p then
            auth.userlist[ u ] = p
            size = size + 1
          end
        else
          done = true
        end
      end
      file.close()
      if size == 0 then
        auth.authenticated = true
      else
        auth.authenticated = false
      end
    else
      auth.authenticated = true
    end
  end

  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local prompt = function()
    local heap = string.format( "%05s", node.heap() )
    return esc( "g" ) .. heap .." $ " .. esc()
  end

  local cls = function()
    return "\012"
  end

  local echo = function( enabled )
    if enabled then
      return "\255\252\001"
    else
      return "\255\251\001"
    end
  end

  local cronfunc = function()
    local luacrond = "crond.lua"
    local lccrond = "crond.lc"
    if file.exists( lccrond ) then
      dofile( lccrond )()
    elseif file.exists( luacrond ) then
      dofile( luacrond )()
    end
  end

  local shellfunc = function( cmdline, auth )
    if not auth.authenticated then
      auth.username = cmdline
      coroutine.yield( "Password: " )
      coroutine.yield( echo( false ) )
      local pass
      while not pass do
        pass = coroutine.yield( "" )
      end
      coroutine.yield( echo( true ) )
      if auth.userlist[ auth.username ] == crypto.toHex( crypto.hash( "sha1", pass ) ) then
        auth.authenticated = true
        auth.userlist = {}
        coroutine.yield( cls() )
      else
        coroutine.yield( "Authentication failed.\n" )
      end
    else
      local argv = {}
      for arg in string.gmatch( cmdline, "%S+" ) do
        table.insert( argv, arg )
      end
      if not argv[ 1 ] then
        return
      elseif argv[ 1 ] == "exit" then
        auth.authenticated = false
      else
        local luaplugin = "shell." .. argv[ 1 ] .. ".lua"
        local lcplugin = "shell." .. argv[ 1 ] .. ".lc"
        if file.exists( lcplugin ) then
          dofile( lcplugin )( unpack( argv, 2 ) )
        elseif file.exists( luaplugin ) then
          dofile( luaplugin )( unpack( argv, 2 ) )
        else
          coroutine.yield( "Unknown command\n" )
        end
      end
    end
  end

  shell = net.createServer( net.TCP, 600 )
  shell:listen( 23, function( lc )
    local cmd, ongoing, thread = {}, false, nil
    local respond = function( sc, req )
      local state, str = coroutine.resume( thread, req, auth )
      if state and str then
        if str == "" then str = " \008" end
        sc:send( str )
      elseif not auth.authenticated then
        sc:close()
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
    readpassfile()
    if not auth.authenticated then
      lc:send( string.format( "%slogin as: ", cls() ) )
    else
      lc:send( prompt() )
    end
  end )
end
