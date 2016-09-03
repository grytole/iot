-- crontab
return function( cmd, arg )
  local crontable = {}

  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local usage = function()
    coroutine.yield( "Usage: crontab CMD [ARG]\n" )
    coroutine.yield( "  crontab list  - print numbered list of cron tasks\n" )
    coroutine.yield( "  crontab add   - add new task\n" )
    coroutine.yield( "  crontab del N - delete task with number N\n" )
    coroutine.yield( "  crontab purge - remove all existing tasks\n" )
    coroutine.yield( "  crontab on N  - enable task with number N\n" )
    coroutine.yield( "  crontab off N - disable task with number N\n" )
  end

  local readcrontab = function()
    local done = false
    if file.exists( "crontab" ) then
      file.open( "crontab", "r" )
      while not done do
        local line = file.readline()
        if line then
          line = string.gsub( line, "\n", "" )
          table.insert( crontable, line )
        else
          done = true
        end
      end
      file.close()
    end
  end

  local savecrontab = function()
    file.open( "crontab", "w" )
    for n, line in ipairs( crontable ) do
      file.writeline( line )
    end
    file.close()
  end

  local ask = function( message )
    local response
    coroutine.yield( message )
    while not response do
      response = coroutine.yield( "" )
    end
    return response
  end

  if not cmd then
    usage()
  else
    readcrontab()
    if cmd == "list" then
      for n, line in ipairs( crontable ) do
        if string.match( line, "^#" ) then
          line = string.gsub( line, "^(#%s*)", "" )
          coroutine.yield( string.format( "%d\t%s%s%s\n", n, esc( "r" ), line, esc() ) )
        else
          coroutine.yield( string.format( "%d\t%s%s%s\n", n, esc( "g" ), line, esc() ) )
        end
      end
    elseif cmd == "on" or cmd == "off" then
      arg = tonumber( arg )
      if not arg then
        usage()
      elseif arg <= 0 or arg > #crontable then
        coroutine.yield( "Failure: argument not in range.\n" )
      else
        local taskoff = string.match( crontable[ arg ], "^#" )
        if cmd == "off" and not taskoff then
          crontable[ arg ] = string.format( "# %s", crontable[ arg ] )
          savecrontab()
          coroutine.yield( "Success: cron task disabled.\n" )
        elseif cmd == "on" and taskoff then
          crontable[ arg ] = string.gsub( crontable[ arg ], "^(#%s*)", "" )
          savecrontab()
          coroutine.yield( "Success: cron task enabled.\n" )
        end
      end
    elseif cmd == "add" then
      coroutine.yield( "Enter new task in this format:\n" )
      coroutine.yield( "  minute(0-59) hour(0-23) day(1-31) month(1-12) weekday(0-7) command\n" )
      local task = ask( string.format( "%s> %s", esc( "m" ), esc( "y" ) ) )
      coroutine.yield( esc() )
      local taskfilter = "^[%#%s]-[%*%d%-%,%/]+%s[%*%d%-%,%/]+%s[%*%d%-%,%/]+%s[%*%d%-%,%/]+%s[%*%d%-%,%/]+%s.+$"
      if string.match( task, taskfilter ) then
        table.insert( crontable, task )
        savecrontab()
        coroutine.yield( "Success: new cron task added.\n" )
      else
        coroutine.yield( "Failure: task format is not valid.\n" )
      end
    elseif cmd == "del" then
      arg = tonumber( arg )
      if not arg then
        usage()
      elseif arg <= 0 or arg > #crontable then
        coroutine.yield( "Failure: argument not in range.\n" )
      else
        coroutine.yield( string.format( "Deletion request for task:\n  %s%s%s\n", esc( "y" ), crontable[ arg ], esc() ) )
        local answer = ask( string.format( "Do you want to delete it (y/N)? " ) )
        if string.match( answer, "^[Yy]" ) then
          table.remove( crontable, arg )
          savecrontab()
          coroutine.yield( "Success: cron task deleted.\n" )
        end
      end
    elseif cmd == "purge" then
      local answer = ask( string.format( "Do you want to delete all tasks (y/N)? " ) )
      if string.match( answer, "^[Yy]" ) then
        crontable = {}
        savecrontab()
        coroutine.yield( "Success: all cron tasks deleted.\n" )
      end
    else
      usage()
    end
  end
end
