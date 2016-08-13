-- mv
return function( src, dst )
  if not src or not dst then
    coroutine.yield( "Usage: mv SRC DEST\n" )
  elseif not file.exists( src ) then
    coroutine.yield( string.format( "Source file '%s' does not exist\n", src ) )
  elseif file.exists( dst ) then
    coroutine.yield( string.format( "Destination file '%s' already exists\n", dst ) )
  else
    file.rename( src, dst )
  end
end
