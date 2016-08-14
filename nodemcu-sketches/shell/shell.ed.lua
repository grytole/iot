-- ed
return function( filename )
  local done = false
  local state = {
    lasterr = "",
    request = "",
    response = "",
    filename = "noname.ed",
    buffer = {},
    cutbuffer = {},
    curraddr = 0,
    prompt = false,
  }

  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local parse = function( req )
    local cmdfilter = "#=acdefhijlnpPqstuwxy"
    local rangefilter = "%d,%%%.%$%+%-;"
    local addrfilter = "%d%+%-%.%$"
    local range, cmd, param = req:match( "^([" .. rangefilter .. "]*)([" .. cmdfilter .. "]?)(.-)$" )
    if cmd == "" then
      cmd = "p"
      if range == "" then
        range = tostring( state.curraddr + 1 )
      end
    elseif cmd == "=" and range == "" then
      range = tostring( #state.buffer )
    elseif cmd == "j" and range == "" then
      range = tostring( state.curraddr ) .. "," .. tostring( state.curraddr + 1 )
    end
    range = range:gsub( "^[,%%;]$", {
      [ "," ] = "1," .. #state.buffer,
      [ "%" ] = "1," .. #state.buffer,
      [ ";" ] = state.curraddr .. "," .. #state.buffer,
    } )
    local addrfrom, addrto = range:match( "^([" .. addrfilter .. "]*),?([" .. addrfilter .. "]-)$" )
    addrfrom = addrfrom:gsub( "^[%.%$]?$", {
      [ "" ] = state.curraddr,
      [ "." ] = state.curraddr,
      [ "$" ] = #state.buffer,
    } )
    addrto = addrto:gsub( "^[%.%$]?$", {
      [ "" ] = addrfrom,
      [ "." ] = state.curraddr,
      [ "$" ] = #state.buffer,
    } )
    return tonumber( addrfrom ), tonumber( addrto ), cmd, param
  end

  if filename then
    if not file.exists( filename ) then
      coroutine.yield( filename .. ": No such file\n" )
    else
      local done = false
      file.open( filename, "r" )
      while not done do
        local line = file.readline()
        if line then
          line = string.gsub( line, "\n", "" )
          table.insert( state.buffer, line )
        else
          done = true
        end
      end
      file.close()
      coroutine.yield( file.list()[ filename ] .. "\n" )
    end
    state.curraddr = #state.buffer
    state.filename = filename
  end

  coroutine.yield( esc( "y" ) )

  while not done do
    if state.response ~= "" then state.response = esc() .. state.response .. esc( "y" ) end
    state.request = coroutine.yield( state.response )
    if state.request then
      local addrfrom, addrto, cmd, param = parse( state.request )

      if cmd == "#" then
        state.response = ""

      elseif cmd == "=" then
        state.response = addrto .. "\n"

      elseif cmd == "a" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "c" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "d" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrfrom > #state.buffer or addrfrom > addrto then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        else
          state.cutbuffer = {}
          for i = addrfrom, addrto do
            table.insert( state.cutbuffer, table.remove( state.buffer, addrfrom ) )
          end
          if addrfrom >= #state.buffer then
            state.curraddr = #state.buffer
          else
            state.curraddr = addrfrom
          end
        end

      elseif cmd == "e" then
        state.response = ""
        state.buffer = {}
        local filename = param:gsub( "^%s*(.-)%s*$", "%1" )
        if filename == "" then
          state.filename = "noname.ed"
        else
          local done = false
          file.open( filename, "r" )
          while not done do
            local line = file.readline()
            if line then
              line = string.gsub( line, "\n", "" )
              table.insert( state.buffer, line )
            else
              done = true
            end
          end
          file.close()
          state.response = file.list()[ filename ] .. "\n"
          state.filename = filename
        end
        state.curraddr = #state.buffer

      elseif cmd == "f" then
        state.response = ""
        local filename = param:gsub( "^%s*(.-)%s*$", "%1" )
        if filename == "" then
          state.response = state.filename .. "\n"
        else
          state.filename = filename
        end

      elseif cmd == "h" then
        state.response = state.lasterr

      elseif cmd == "i" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "j" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrfrom > #state.buffer or addrfrom >= addrto then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        else
          state.cutbuffer = {}
          for i = addrfrom, addrto do
            table.insert( state.cutbuffer, table.remove( state.buffer, addrfrom ) )
          end
          table.insert( state.buffer, addrfrom, table.concat( state.cutbuffer ) )
          state.curraddr = addrfrom
        end

      elseif cmd == "l" or cmd == "n" or cmd == "p" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrfrom > #state.buffer or addrfrom > addrto then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        else
          for i = addrfrom, addrto do
              if cmd == "l" then
                coroutine.yield( string.format( "%s%s$\n%s", esc(), state.buffer[ i ]:gsub( "(%$)", "\\$" ), esc( "y" ) ) )
              elseif cmd == "n" then
                coroutine.yield( string.format( "%s%4d\t%s\n%s", esc(), i, state.buffer[ i ], esc( "y" ) ) )
              elseif cmd == "p" then
                coroutine.yield( string.format( "%s%s\n%s", esc(), state.buffer[ i ], esc( "y" ) ) )
              end
          end
          state.curraddr = addrto
        end

      elseif cmd == "m" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "P" then
        state.response = ""
        state.prompt = not state.prompt

      elseif cmd == "q" then
        state.response = nil
        done = true

      elseif cmd == "r" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "s" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "t" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrfrom > #state.buffer or addrfrom > addrto then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        else
          state.response = "?\n"
          state.lasterr = "TODO\n"
        end

      elseif cmd == "u" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "w" then
        state.response = "?\n"
        state.lasterr = "TODO\n"

      elseif cmd == "x" then
        state.response = ""
        if addrto < 0 or addrto > #state.buffer then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        elseif #state.cutbuffer == 0 then
          state.response = "?\n"
          state.lasterr = "Cut buffer is empty\n"
        else
          for i = 1, #state.cutbuffer do
            table.insert( state.buffer, addrto + i, state.cutbuffer[ i ] )
          end
          state.curraddr = addrto + #state.cutbuffer
        end

      elseif cmd == "y" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrfrom > #state.buffer or addrfrom > addrto then
          state.response = "?\n"
          state.lasterr = "Wrong address\n"
        else
          state.cutbuffer = {}
          for i = addrfrom, addrto do
            table.insert( state.cutbuffer, state.buffer[ i ] )
          end
        end

      else
        state.response = "?\n"
        state.lasterr = "Unknown command\n"

      end
    else
      state.response = ""
    end
  end
end
