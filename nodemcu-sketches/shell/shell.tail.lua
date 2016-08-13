-- tail
return function( filename, numlines )
  local numlines = numlines or 10
  if not filename or not tonumber( numlines ) or tonumber( numlines ) < 1 then
    coroutine.yield( "Usage: tail FILE [NUMLINES]\n" )
  elseif not file.exists( filename ) then
    coroutine.yield( string.format( "File '%s' does not exist\n", filename ) )
  else
    local done, lines = false, 0
    file.open( filename, "r" )
    while not done do
      if file.readline() then
        lines = lines + 1
      else
        done = true
      end
    end
    file.seek( "set", 0 )
    for i = 1, lines do
      local line = file.readline()
      if line then
        if i > lines - tonumber( numlines ) then
          coroutine.yield( line )
        end
      else
        break
      end
    end
    file.close()
  end
end
