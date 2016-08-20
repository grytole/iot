-- ed-parser
return function( state )
  local search = function( retype, re )
    local repeated = false
    if re == "" then
      re = state.lastsearch
      repeated = true
    end
    if re == "" then
      return ""
    else
      local from, to, iter
      state.lastsearch = re
      if retype == "/" then
        if repeated then
          from, to, iter = 1, #state.buffer, 1
        else
          from, to, iter = 0, #state.buffer - 1, 1
        end
      else
        if repeated then
          from, to, iter = #state.buffer - 1, 0, -1
        else
          from, to, iter = #state.buffer, 1, -1
        end
      end
      for i = from, to, iter do
        local linenum = ( ( i + state.curraddr - 1 ) % #state.buffer ) + 1
        if string.match( state.buffer[ linenum ], re ) then
          return linenum
        end
      end
      return ""
    end
  end

  local notfound = false
  local cmdfilter = "(.?)"
  local rangefilter = "([%d,%%%.%$;]*)"
  local retype = string.match( state.request, "^[/%?]" )
  if retype then
    rangefilter = "[/%?]([^/%?%c]*)[/%?]?"
  end
  local range, cmd, param = string.match( state.request, "^" .. rangefilter .. cmdfilter .. "(.-)$" )
  param = string.gsub( param, "^%s*(.-)%s*$", "%1" )
  if retype then
    range = search( retype, range )
    if range == "" then
      notfound = true
    end
  end
  if cmd == "" then
    cmd = "p"
    if range == "" then
      range = tostring( state.curraddr + 1 )
    end
  elseif cmd == "=" and range == "" then
    range = tostring( #state.buffer )
  elseif cmd == "j" and range == "" then
    range = tostring( state.curraddr ) .. "," .. tostring( state.curraddr + 1 )
  elseif cmd == "r" and range == "" then
    range = tostring( #state.buffer )
  elseif ( cmd == "w" or cmd == "W" ) and range == "" then
    range = "1," .. tostring( #state.buffer )
  elseif ( cmd == "m" or cmd == "t" ) and param == "" then
    param = state.curraddr
  end
  range = string.gsub( range, "^[,%%;]$", {
    [ "," ] = "1," .. #state.buffer,
    [ "%" ] = "1," .. #state.buffer,
    [ ";" ] = state.curraddr .. "," .. #state.buffer,
  } )
  local addrfrom, addrto = string.match( range, "^([%d%.%$]*),?([%d%.%$]-)$" )
  addrfrom = string.gsub( addrfrom, "^[%.%$]?$", {
    [ "" ] = state.curraddr,
    [ "." ] = state.curraddr,
    [ "$" ] = #state.buffer,
  } )
  addrto = string.gsub( addrto, "^[%.%$]?$", {
    [ "" ] = addrfrom,
    [ "." ] = state.curraddr,
    [ "$" ] = #state.buffer,
  } )
  param = string.gsub( param, "^[%.%$]$", {
    [ "." ] = state.curraddr,
    [ "$" ] = #state.buffer,
  } )

  return notfound, tonumber( addrfrom ), tonumber( addrto ), cmd, param
end
