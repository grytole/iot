-- cp
return function( src, dst )
  if not src or not dst then
    coroutine.yield( "Usage: cp SRC DEST\n" )
  elseif not file.exists( src ) then
    coroutine.yield( string.format( "Source file '%s' does not exist\n", src ) )
  elseif file.exists( dst ) then
    coroutine.yield( string.format( "Destination file '%s' already exists\n", dst ) )
  else
    local buf, done = {}, false
    file.open( src, "r" )
    while not done do
      local line = file.readline()
      if line then
        table.insert( buf, line )
      else
        done = true
      end
    end
    file.close()
    file.open( dst, "w" )
    while #buf do
      file.write( table.remove( buf, 1 ) )
    end
    file.close()
  end
end
