-- rm
return function( filename )
  if not filename then
    coroutine.yield( "Usage: rm FILE\n" )
  elseif not file.exists( filename ) then
    coroutine.yield( string.format( "File '%s' does not exist\n", filename ) )
  else
    file.remove( filename )
  end
end
