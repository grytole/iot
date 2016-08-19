-- df
return function()
  local avail, used, total = file.fsinfo()
  local percent = math.floor( ( used * 100 / total ) + 0.5 )
  coroutine.yield( string.format( "   Size    Used   Avail  Use%%\n%7d %7d %7d  %3d%%\n", total, used, avail, percent ) )
end
