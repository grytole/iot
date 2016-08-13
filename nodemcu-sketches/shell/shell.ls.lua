-- ls
return function()
  local esc = function( arg )
    local sgr = { r = 31, g = 32, b = 34, c = 36, m = 35, y = 33, k = 30, w = 37 }
    local code = sgr[ arg ] or 0
    return "\027[" .. code .. "m"
  end
  for name, size in pairs( file.list() ) do
    if name:match( "^shell.-%.lua$" ) then
      name = esc( "c" ) .. name .. esc()
    elseif name:match( "^init.lua$" ) then
      name = esc( "y" ) .. name .. esc()
    end
    coroutine.yield( string.format( "%7d %s\n", size, name ) )
  end
  local left, used, _ = file.fsinfo()
  coroutine.yield( string.format( "\n%7d used\n%7d left\n", used, left ) )
end
