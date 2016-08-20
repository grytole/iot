-- ed
return function( filename )
  local state = {
    done = false,
    lasterr = "",
    request = "",
    response = "",
    filename = "",
    buffer = {},
    cutbuffer = {},
    curraddr = 0,
    lastsearch = "",
    lastsubst = "",
    explanation = false,
    warned = false,
    changed = false,
    err = {
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
    },
  }

  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end

  local doplugin = function( plugin, ... )
    local luaedparser = "shell.ed-parser.lua"
    local lcedparser = "shell.ed-parser.lc"
    local luaedcommands = "shell.ed-commands.lua"
    local lcedcommands = "shell.ed-commands.lc"

    if plugin == "parser" then
      if file.exists( lcedparser ) then
        return dofile( lcedparser )( arg[ 1 ] )
      elseif file.exists( luaedparser ) then
        return dofile( luaedparser )( arg[ 1 ] )
      else
        coroutine.yield( "'ed-parser' plugin missed\n" )
        state.done = true
      end
    elseif plugin == "commands" then
      if file.exists( lcedcommands ) then
        return dofile( lcedcommands )( arg[ 1 ], arg[ 2 ], arg[ 3 ], arg[ 4 ], arg[ 5 ], arg[ 6 ] )
      elseif file.exists( luaedcommands ) then
        return dofile( luaedcommands )( arg[ 1 ], arg[ 2 ], arg[ 3 ], arg[ 4 ], arg[ 5 ], arg[ 6 ] )
      else
        coroutine.yield( "'ed-commands' plugin missed\n" )
        state.done = true
      end
    end
  end

  if filename then
    doplugin( "commands", state, false, 0, 0, "r", filename )
    state.changed = false
  end

  coroutine.yield( esc( "y" ) )

  while not state.done do
    if state.response ~= "" then
      state.response = esc() .. state.response .. esc( "y" )
    end

    state.request = coroutine.yield( state.response )
    state.response = ""

    if state.request then
      local addrnotfound, addrfrom, addrto, cmd, param = doplugin( "parser", state )
      doplugin( "commands", state, addrnotfound, addrfrom, addrto, cmd, param )
    end
  end
end
