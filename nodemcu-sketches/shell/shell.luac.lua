-- luac
return function( filename )
  if not filename then
    coroutine.yield( "Usage: luac FILE\n" )
  elseif not file.exists( filename ) then
    coroutine.yield( string.format( "File '%s' does not exist\n", filename ) )
  else
    node.compile( filename )
  end
end
