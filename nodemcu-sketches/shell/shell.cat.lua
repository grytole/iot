-- cat
return function( filename )
  if not filename then
    coroutine.yield( "Usage: cat FILE\n" )
  elseif not file.exists( filename ) then
    coroutine.yield( string.format( "File '%s' does not exist\n", filename ) )
  else
    local done = false
    file.open( filename, "r" )
    while not done do
      local line = file.readline()
      if line then
        coroutine.yield( line )
      else
        done = true
      end
    end
    file.close()
  end
end
