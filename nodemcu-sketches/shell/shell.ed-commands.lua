-- ed-commands
return function( state, addrnotfound, addrfrom, addrto, cmd, param )
  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local seterror = function( desc )
    state.lasterr = desc
    state.response = state.explanation and "?\n" .. state.lasterr or "?\n"
  end

  if addrnotfound then
    seterror( state.err.nomatch )

  elseif cmd == "#" then

  elseif cmd == "=" then
    state.response = addrto .. "\n"

  elseif cmd == "a" or cmd == "c" or cmd == "i" then
    if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
    elseif cmd ~= "a" and ( addrfrom == 0 or addrto == 0 ) then
      seterror( state.err.invaddr )
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
    if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
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
    if cmd == "e" and state.changed and not state.warned then
      seterror( state.err.unsaved )
      state.warned = true
    else
      state.buffer = {}
      if param == "" then
        param = state.filename
      end
      if not file.exists( param ) then
        seterror( param .. ": " .. state.err.nofile )
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
    end

  elseif cmd == "f" then
    if param == "" then
      if state.filename == "" then
        seterror( state.err.nofilename )
      else
        state.response = state.filename .. "\n"
      end
    else
      state.filename = param
    end

  elseif cmd == "h" then
    state.response = state.lasterr

  elseif cmd == "H" then
    state.explanation = not state.explanation

  elseif cmd == "j" then
    if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom >= addrto then
      seterror( state.err.invaddr )
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
    if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
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
    local dest = tonumber( param )
    if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
    elseif not dest or dest < 0 or dest > #state.buffer then
      seterror( state.err.invdest )
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
          seterror( state.err.nochange )
        end
      end
    end

  elseif cmd == "q" or cmd == "Q" then
    if cmd == "q" and state.changed and not state.warned then
      seterror( state.err.unsaved )
      state.warned = true
    else
      state.response = nil
      state.done = true
    end

  elseif cmd == "r" then
    if param == "" then
      param = state.filename
    end
    if param == "" then
      seterror( state.err.nofilename )
    elseif not file.exists( param ) then
      seterror( param .. ": " .. state.err.nofile )
    elseif addrto < 0 or addrto > #state.buffer then
      seterror( state.err.invaddr )
    else
      local done, bytes = false, 0
      file.open( param, "r" )
      while not done do
        local line = file.readline()
        if line then
          addrto = addrto + 1
          bytes = bytes + #line
          line = string.gsub( line, "\n", "" )
          table.insert( state.buffer, addrto, line )
        else
          done = true
        end
      end
      file.close()
      state.response = bytes .. "\n"
      if state.filename == "" then
        state.filename = param
      end
      state.changed = true
      state.warned = false
      state.curraddr = addrto
    end

  elseif cmd == "s" then
    if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
    else
      local matched, repeatsubst, repeatsuffix = false, false, ""
      local re, replacement, suffix, dsuffix, gsuffix, psuffix = "", "", "", nil, nil, nil
      if param == "" then
        param = state.lastsubst
        repeatsubst = true
      elseif string.match( param, "^[%dgp]*$" ) then
        repeatsuffix = param
        param = state.lastsubst
        repeatsubst = true
      end
      if param == "" then
        seterror( state.err.nopattern )
      else
        local delim = string.sub( param, 1, 1 )
        local chunks = {}
        local filter = "[^%" .. delim .. "]*"
        string.gsub( param, filter, function( l ) table.insert( chunks, l ) end )
        re = chunks[ 2 ] or ""
        replacement = chunks[ 4 ] or ""
        if repeatsubst then
          suffix = repeatsuffix
        else
          suffix = chunks[ 6 ] or "p"
        end
        dsuffix = string.match( suffix, "%d+" )
        gsuffix = string.match( suffix, "g" )
        psuffix = string.match( suffix, "p" )
        for i = addrfrom, addrto do
          if string.match( state.buffer[ i ], re ) then
            if dsuffix and not gsuffix then
              local head, tail = 1, 1
              for j = 1, tonumber( dsuffix ) do
                head, tail = string.find( state.buffer[ i ], re, tail )
                if not head then
                  break
                elseif j == tonumber( dsuffix ) then
                  state.cutbuffer = {}
                  table.insert( state.cutbuffer, state.buffer[ i ] )
                  state.buffer[ i ] = string.sub( state.buffer[ i ], 1, head - 1 ) .. replacement .. string.sub( state.buffer[ i ], tail + 1 )
                  state.curraddr = i
                  matched = true
                end
              end
            else
              state.cutbuffer = {}
              table.insert( state.cutbuffer, state.buffer[ i ] )
              if gsuffix then
                state.buffer[ i ] = string.gsub( state.buffer[ i ], re, replacement )
              else
                state.buffer[ i ] = string.gsub( state.buffer[ i ], re, replacement, 1 )
              end
              state.curraddr = i
              matched = true
            end
          end
        end
        if psuffix and matched then
          coroutine.yield( string.format( "%s\n", state.buffer[ state.curraddr ] ) )
        end
      end
      if not matched then
        seterror( state.err.nomatch )
      elseif not repeatsubst then
        state.lastsubst = param
      end
    end

  elseif cmd == "w" or cmd == "W" then
    if addrfrom <= 0 or addrto <= 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
    elseif param == "" and state.filename == "" then
      seterror( state.err.nofilename )
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
    if addrto < 0 or addrto > #state.buffer then
      seterror( state.err.invaddr )
    elseif #state.cutbuffer == 0 then
      seterror( state.err.cutempty )
    else
      for i = 1, #state.cutbuffer do
        table.insert( state.buffer, addrto + i, state.cutbuffer[ i ] )
      end
      state.curraddr = addrto + #state.cutbuffer
      state.changed = true
      state.warned = false
    end

  elseif cmd == "y" then
    if addrfrom < 0 or addrto < 0 or addrto > #state.buffer or addrfrom > addrto then
      seterror( state.err.invaddr )
    else
      state.cutbuffer = {}
      for i = addrfrom, addrto do
        table.insert( state.cutbuffer, state.buffer[ i ] )
      end
    end

  else
    seterror( state.err.unknown )
  end
end
