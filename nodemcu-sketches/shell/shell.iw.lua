-- iw
return function( cmd, arg1, arg2 )
  if not cmd then
    coroutine.yield( "Usage: iw CMD [ARG1 [ARG2]]\n" )
  end
  if cmd == "scan" then
    local result, done = {}, false
    local listap = function( t )
      table.insert( result, "\n" )
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      table.insert( result, ":                             SSID :             BSSID : RSSI :     AUTH : CH :\n" )
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      for bssid, v in pairs( t ) do
        local ssid, rssi, auth, channel = string.match( v, "([^,]+),([^,]+),([^,]+),([^,]*)" )
        if auth == "1" then
          auth = "open"
        elseif auth == "2" then
          auth = "wpa"
        elseif auth == "3" then
          auth = "wpa2"
        elseif auth == "4" then
          auth = "wpa_wpa2"
        end
        table.insert( result, string.format( ": %32s : %17s : %4s : %8s : %2s :\n", ssid, bssid, rssi, auth, channel ) )
      end
      table.insert( result, "-------------------------------------------------------------------------------\n" )
      done = true
    end
    coroutine.yield( "Scanning" )
    wifi.sta.getap( 1, listap )
    while not done do
      coroutine.yield( " ." )
    end
    while #result do
      coroutine.yield( table.remove( result, 1 ) )
    end
  elseif cmd == "connect" then
    if not arg1 or not arg2 then
      coroutine.yield( "Usage: iw connect SSID PASSWORD\n" )
    else
      wifi.setmode( wifi.STATION )
      wifi.sta.config( arg1, arg2 )
    end
  else
    coroutine.yield( "Unknown CMD parameter\n" )
  end
end
