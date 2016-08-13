-- grep
return function( regexp, filename )
  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end
  local filename = filename or "*"
  local filelist = {}
  if not regexp then
    coroutine.yield( "Usage: grep REGEXP [FILE]\n" )
  elseif file.exists( filename ) then
    table.insert( filelist, filename )
  elseif filename:match( "[%*%?]" ) then
    local wildcards = { [ "." ] = "%.", [ "*" ] = ".*", [ "?" ] = "." }
    local pattern = "^" .. filename:gsub( "([%.%*%?])", wildcards ) .. "$"
    for name, _ in pairs( file.list() ) do
      if name:match( pattern ) then
        table.insert( filelist, name )
      end
    end
  end
  for _, name in ipairs( filelist ) do
    local done, linenum = false, 0
    file.open( name, "r" )
    while not done do
      local line = file.readline()
      if line then
        linenum = linenum + 1
        local hit = line:match( regexp )
        if hit then
          local info = esc( "m" ) .. name .. esc( "c" ) .. ":" .. esc( "m" ) .. linenum .. esc( "c" ) .. ":" .. esc()
          coroutine.yield( info .. line:gsub( hit, esc( "r" ) .. hit .. esc() ) )
        end
      else
        done = true
      end
    end
    file.close()
  end
end
