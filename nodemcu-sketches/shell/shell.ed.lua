-- ed
return function( filename )
  local done = false

  local state = {
    lasterr = "",
    request = "",
    response = "",
    filename = "",
    buffer = {},
    cutbuffer = {},
    curraddr = 0,
    prompt = false,
    explanation = false,
    warned = false,
    changed = false,
  }

  local err = {
    nofile = "No such file\n",
    nofilename = "No current filename\n",
    invaddr = "Invalid address\n",
    invdest = "Invalid destination\n",
    invsuffix = "Invalid command suffix\n",
    nochange = "Makes no change\n",
    cutempty = "Nothing to put\n",
    unknown = "Unknown command\n",
    unsaved = "Warning: file modified\n",
    nopattern = "No previous pattern\n",
    nomatch = "No match\n",
  }

  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local seterror = function( desc )
    state.lasterr = desc
    state.response = state.explanation and "?\n" .. state.lasterr or "?\n"
  end

  local parse = function( req )
    local cmdfilter = "#=acdeEfhHijlmnpPqQrstuwWxy"
    local rangefilter = "%d,%%%.%$%+%-;"
    local addrfilter = "%d%+%-%.%$"
    local range, cmd, param = string.match( req, "^([" .. rangefilter .. "]*)([" .. cmdfilter .. "]?)(.-)$" )
    param = string.gsub( param, "^%s*(.-)%s*$", "%1" )
    if cmd == "" then
      cmd = "p"
      if range == "" then
        range = tostring( state.curraddr + 1 )
      end
    elseif cmd == "=" and range == "" then
      range = tostring( #state.buffer )
    elseif cmd == "j" and range == "" then
      range = tostring( state.curraddr ) .. "," .. tostring( state.curraddr + 1 )
    elseif cmd == "r" and range == "" then
      range = tostring( #state.buffer )
    elseif ( cmd == "w" or cmd == "W" ) and range == "" then
      range = "1," .. tostring( #state.buffer )
    elseif ( cmd == "m" or cmd == "t" ) and param == "" then
      param = state.curraddr
    end
    range = string.gsub( range, "^[,%%;]$", {
      [ "," ] = "1," .. #state.buffer,
      [ "%" ] = "1," .. #state.buffer,
      [ ";" ] = state.curraddr .. "," .. #state.buffer,
    } )
    local addrfrom, addrto = string.match( range, "^([" .. addrfilter .. "]*),?([" .. addrfilter .. "]-)$" )
    addrfrom = string.gsub( addrfrom, "^[%.%$]?$", {
      [ "" ] = state.curraddr,
      [ "." ] = state.curraddr,
      [ "$" ] = #state.buffer,
    } )
    addrto = string.gsub( addrto, "^[%.%$]?$", {
      [ "" ] = addrfrom,
      [ "." ] = state.curraddr,
      [ "$" ] = #state.buffer,
    } )
    param = string.gsub( param, "^[%.%$]$", {
      [ "." ] = state.curraddr,
      [ "$" ] = #state.buffer,
    } )
    return tonumber( addrfrom ), tonumber( addrto ), cmd, param
  end

  if filename then
    if not file.exists( filename ) then
      coroutine.yield( filename .. ": " .. err.nofile )
    else
      local done, bytes = false, 0
      file.open( filename, "r" )
      while not done do
        local line = file.readline()
        if line then
          bytes = bytes + #line
          line = string.gsub( line, "\n", "" )
          table.insert( state.buffer, line )
        else
          done = true
        end
      end
      file.close()
      coroutine.yield( bytes .. "\n" )
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

      elseif cmd == "a" or cmd == "c" or cmd == "i" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        elseif cmd ~= "a" and ( addrfrom == 0 or addrto == 0 ) then
          seterror( err.invaddr )
        else
          local done, i = false, addrto
          if cmd == "a" then
            i = i + 1
          elseif cmd == "c" then
            state.cutbuffer = {}
            for _ = addrfrom, addrto do
              table.insert( state.cutbuffer, table.remove( state.buffer, addrfrom ) )
            end
            i = addrfrom
          end
          while not done do
            local line = coroutine.yield( "" )
            if line ~= "." then
              table.insert( state.buffer, i, line )
              i = i + 1
            else
              done = true
            end
          end
          state.curraddr = i - 1
          state.changed = true
          state.warned = false
        end

      elseif cmd == "d" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        else
          state.cutbuffer = {}
          for _ = addrfrom, addrto do
            table.insert( state.cutbuffer, table.remove( state.buffer, addrfrom ) )
          end
          if addrfrom >= #state.buffer then
            state.curraddr = #state.buffer
          else
            state.curraddr = addrfrom
          end
          state.changed = true
          state.warned = false
        end

      elseif cmd == "e" or cmd == "E" then
        state.response = ""
        state.buffer = {}
        if param == "" then
          param = state.filename
        end
        if not file.exists( param ) then
          seterror( param .. ": " .. err.nofile )
        else
          local done, bytes = false, 0
          file.open( param, "r" )
          while not done do
            local line = file.readline()
            if line then
              bytes = bytes + #line
              line = string.gsub( line, "\n", "" )
              table.insert( state.buffer, line )
            else
              done = true
            end
          end
          file.close()
          state.response = bytes .. "\n"
          state.filename = param
          state.changed = false
          state.warned = false
        end
        state.curraddr = #state.buffer

      elseif cmd == "f" then
        state.response = ""
        if param == "" then
          if state.filename == "" then
            seterror( err.nofilename )
          else
            state.response = state.filename .. "\n"
          end
        else
          state.filename = param
        end

      elseif cmd == "h" then
        state.response = state.lasterr

      elseif cmd == "H" then
        state.response = ""
        state.explanation = not state.explanation

      elseif cmd == "j" then
        state.response = ""
        if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom >= addrto then
          seterror( err.invaddr )
        else
          state.cutbuffer = {}
          for _ = addrfrom, addrto do
            table.insert( state.cutbuffer, table.remove( state.buffer, addrfrom ) )
          end
          table.insert( state.buffer, addrfrom, table.concat( state.cutbuffer ) )
          state.curraddr = addrfrom
          state.changed = true
          state.warned = false
        end

      elseif cmd == "l" or cmd == "n" or cmd == "p" then
        state.response = ""
        if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        else
          coroutine.yield( esc() )
          for i = addrfrom, addrto do
              if cmd == "l" then
                coroutine.yield( string.format( "%s$\n", string.gsub( state.buffer[ i ], "(%$)", "\\$" ) ) )
              elseif cmd == "n" then
                coroutine.yield( string.format( "%d\t%s\n", i, state.buffer[ i ] ) )
              else
                coroutine.yield( string.format( "%s\n", state.buffer[ i ] ) )
              end
          end
          coroutine.yield( esc( "y" ) )
          state.curraddr = addrto
        end

      elseif cmd == "m" or cmd == "t" then
        state.response = ""
        local dest = tonumber( param )
        if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        elseif not dest or dest < 0 or dest > #state.buffer then
          seterror( err.invdest )
        else
          local buf = {}
          if cmd == "t" then
            for i = addrfrom, addrto do
              table.insert( buf, state.buffer[ i ] )
            end
            for i = 1, #buf do
              table.insert( state.buffer, dest + i, buf[ i ] )
            end
            state.curraddr = dest + #buf
            state.changed = true
            state.warned = false
          else
            if dest < addrfrom - 1 then
              for _ = addrfrom, addrto do
                table.insert( buf, table.remove( state.buffer, addrfrom ) )
              end
              for i = 1, #buf do
                table.insert( state.buffer, dest + i, buf[ i ] )
              end
              state.curraddr = dest + #buf
              state.changed = true
              state.warned = false
            elseif dest > addrto then
              for _ = addrfrom, addrto do
                table.insert( buf, table.remove( state.buffer, addrfrom ) )
              end
              for i = 1, #buf do
                table.insert( state.buffer, dest + i - #buf, buf[ i ] )
              end
              state.curraddr = dest
              state.changed = true
              state.warned = false
            else
              seterror( err.nochange )
            end
          end
        end

      elseif cmd == "P" then
        state.response = ""
        state.prompt = not state.prompt

      elseif cmd == "q" then
        if state.warned or not state.changed then
          state.response = nil
          done = true
        else
          seterror( err.unsaved )
          state.warned = true
        end

      elseif cmd == "Q" then
        state.response = nil
        done = true

      elseif cmd == "r" then
        seterror( "TODO\n" )

      elseif cmd == "s" then
        seterror( "TODO\n" )

      elseif cmd == "u" then
        seterror( "TODO\n" )

      elseif cmd == "w" or cmd == "W" then
        state.response = ""
        if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        elseif param == "" and state.filename == "" then
          seterror( err.nofilename )
        else
          local bytes = 0
          if param == "" then
            param = state.filename
          else
            if state.filename == "" then
              state.filename = param
            end
          end
          if cmd == "w" then
            file.open( param, "w+" )
          else
            file.open( param, "a+" )
          end
          for i = addrfrom, addrto  do
            bytes = bytes + #state.buffer[ i ] + 1
            file.writeline( state.buffer[ i ] )
          end
          file.close()
          state.response = bytes .. "\n"
          if addrfrom == 1 and addrto == #state.buffer then
            state.changed = false
          end
          state.warned = false
        end

      elseif cmd == "x" then
        state.response = ""
        if addrto < 0 or addrto > #state.buffer then
          seterror( err.invaddr )
        elseif #state.cutbuffer == 0 then
          seterror( err.cutempty )
        else
          for i = 1, #state.cutbuffer do
            table.insert( state.buffer, addrto + i, state.cutbuffer[ i ] )
          end
          state.curraddr = addrto + #state.cutbuffer
          state.changed = true
          state.warned = false
        end

      elseif cmd == "y" then
        state.response = ""
        if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
          seterror( err.invaddr )
        else
          state.cutbuffer = {}
          for i = addrfrom, addrto do
            table.insert( state.cutbuffer, state.buffer[ i ] )
          end
        end

      else
        seterror( err.unknown )

      end
    else
      state.response = ""
    end
  end
end
