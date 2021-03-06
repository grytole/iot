-- head
return function( filename, numlines )
  local numlines = numlines or 10
  if not filename or not tonumber( numlines ) or tonumber( numlines ) < 1 then
    coroutine.yield( "Usage: head FILE [NUMLINES]\n" )
  elseif not file.exists( filename ) then
    coroutine.yield( string.format( "File '%s' does not exist\n", filename ) )
  else
    file.open( filename, "r" )
    for i = 1, tonumber( numlines ) do
      local line = file.readline()
      if line then
        coroutine.yield( line )
      else
        break
      end
    end
    file.close()
  end
end
