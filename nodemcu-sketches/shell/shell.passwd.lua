-- passwd
return function( username )
  local userlist = {}

  local readpassfile = function()
    local done = false
    file.open( "passwd", "r" )
    while not done do
      local line = file.readline()
      if line then
        local u, p = string.match( line, "^([^%c:]+):(%w+)" )
        userlist[ u ] = p
      else
        done = true
      end
    end
    file.close()
  end

  local savepassfile = function()
    file.open( "passwd", "w" )
    for u, p in pairs( userlist ) do
      file.writeline( u .. ":" .. p )
    end
    file.close()
  end

  local ask = function( message )
    local response
    coroutine.yield( message )
    while not response do
      response = coroutine.yield( "" )
    end
    return response
  end

  local checkpassword = function( user, pass )
    return userlist[ user ] == crypto.toHex( crypto.hash( "sha1", pass ) )
  end

  local asknewpassword = function()
    local passnew = ask( "New password: " )
    local passredo = ask( "Retype new password: " )
    if passnew == passredo then
      if passnew == "" then
        return ""
      else
        return crypto.toHex( crypto.hash( "sha1", passnew ) )
      end
    else
      coroutine.yield( "Failure: passwords do not match.\n" )
    end
  end

  local addnewuser = function( user )
    local answer = ask( string.format( "User '%s' is not found. Do you want to create him [y/N]? ", user ) )
    if string.match( answer, "^[Yy]" ) then
      local hash = asknewpassword()
      if hash then
        if hash == "" then
          coroutine.yield( string.format( "Failure: unable to create user with empty password.\n" ) )
        else
          userlist[ user ] = hash
          savepassfile()
          coroutine.yield( string.format( "User '%s' created.\n", user ) )
        end
      end
    end
  end

  if not username then
    username = ask( "Username: " )
  end

  if file.exists( "passwd" ) then
    readpassfile()
    if userlist[ username ] then
      local password = ask( "Old password: " )
      if not checkpassword( username, password ) then
        coroutine.yield( "Failure: wrong password.\n" )
      else
        coroutine.yield( string.format( "Changing password for '%s'.\n", username ) )
        local hash = asknewpassword()
        if hash then
          if hash == "" then
            local answer = ask( string.format( "Password is not set. Do you want to delete user '%s' [y/N]? ", username ) )
            if string.match( answer, "^[Yy]" ) then
              userlist[ username ] = nil
              savepassfile()
              coroutine.yield( string.format( "User '%s' deleted.\n", username ) )
            end
          else
            userlist[ username ] = hash
            savepassfile()
            coroutine.yield( string.format( "Password for user '%s' updated.\n", username ) )
          end
        end
      end
    else
      addnewuser( username )
    end
  else
    addnewuser( username )
  end
end
