-- dofile("wget.lua").wget("https://example.com/path/target.file")
-- dofile("wget.lua").wget("https://example.com/path/target.file", "dest.file")

local M = {}
do
  local host, port, path, filename
  local checked, pending = false, nil

  local parseUrl = function( url )
    local proto, fullpath = url:match( "(%w+)://(.+)" )
    if not proto then
      proto = "http"
      fullpath = url
    end
    local host, port, path = fullpath:match( "([^/^:]+):?(%d*)(.*)" )
    if port == "" then
      if proto == "https" then port = 443 else port = 80 end
    end
    local fname = path:match( ".*/([^?]+)" )
    return host, port, path, fname
  end

  local secure = function( port )
    if port == 443 then
      return 1
    else
      return 0
    end
  end

  local createRequest = function( method, path, host, from, size )
    local req = {}
    table.insert( req, method .. " " .. path .. " HTTP/1.1\r\n" )
    table.insert( req, "Host: " .. host .. "\r\n" )
    table.insert( req, "Connection: keep-alive\r\n" )
    table.insert( req, "Accept: */*\r\n" )
    table.insert( req, "Range: bytes=" .. from .. "-" .. from + size - 1 .. "\r\n" )
    table.insert( req, "\r\n" )
    return table.concat( req )
  end

  local parseResponse = function( resp )
    local headers = {}
    headers.code = resp:match( "HTTP/[%d.]+ (%d+).*\r\n" )
    headers.length = resp:match( "Content%-Length: (%d+)\r\n" )
    headers.accranges = resp:match( "Accept%-Ranges: (%w+)\r\n" )
    headers.range = resp:match( "Content%-Range: .- (.-)\r\n" )
    local payload = resp:match( "\r\n\r\n(.*)" )
    return headers, payload
  end

  local handleResponse = function( resp )
    local headers, payload = parseResponse( resp )
    if not checked then
      if headers.code == "200" then
        if headers.length then
          if headers.accranges == "bytes" then
            checked = true
            file.open( filename, "w" )
            return createRequest( "GET", path, host, 0, 1024 )
          else
            print( "[FAIL] server does not support partial downloads" )
          end
        else
          print( "[FAIL] payload size is absent in server response" )
        end
      else
        print( "[FAIL] server responded with code:", headers.code )
      end
    else
      if headers.code == "206" then
        if headers.range then
          local start, stop, total = headers.range:match( "(%d+)%-(%d+)/(%d+)" )
          local sz = #total
          start, stop, total = tonumber( start ), tonumber( stop ), tonumber( total )
          if stop - start + 1 == #payload then
            local pbar = ( stop + 1 ) * 100 / total
            print( string.format( "[%3d%%] %" .. sz .. "s - %" .. sz .. "s / %" .. sz .. "s", pbar, start + 1, stop + 1, total ) )
            file.write( payload )
            if stop + 1 == total then
              file.close()
              print( "[DONE] target saved as '" .. filename .. "'" )
            else
              local from = stop + 1
              local size = 1024
              if from + size > total then
                size = total - from
              end
              return createRequest( "GET", path, host, from, size )
            end
          else
            pending = resp
          end
        else
          print( "[FAIL] ranged payload size is absent in server response" )
          file.close()
        end
      else
        print( "[FAIL] server responded with code:", headers.code )
        file.close()
      end
    end
  end

  local wget = function( url, target )
    host, port, path, fname = parseUrl( url )
    filename = target or fname

    if file.exists( filename ) then
      print( "[FAIL] target file '" .. filename .. "' already exists" )
      return
    end

    local send = function( sc, req )
      if req then
        sc:send( req )
      elseif not pending then
        sc:close()
      end
    end

    local c = net.createConnection( net.TCP, secure( port ) )

    c:on( "connection", function( cc )
      print()
      local req = createRequest( "HEAD", path, host, 0, 1024 )
      send( cc, req )
    end )

    c:on( "receive", function( rc, payload )
      if pending then
        payload = pending .. payload
        pending = nil
      end
      local req = handleResponse( payload )
      send( rc, req )
    end )

    c:connect( port, host )
  end

  M = { wget = wget }
end
return M
