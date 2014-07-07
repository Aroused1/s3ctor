--Plugin Details. If you make contributions, add yourself to the Author here
PLUGIN.Title = "S3ctor"
PLUGIN.Description = "A plugin for Admin created Warps, designed for easy enabling/disabling of jumps"
PLUGIN.Version = "0.2"
PLUGIN.Author = "Kyros <grimd.666@gmail.com>", "Aroused1 <LustForRust@hotmail.com>"

--Init hook. Setup commands and grab our datafile.
function PLUGIN:Init()
  --Register commands
  self:AddChatCommand("setjump", self.setJump)
  self:AddChatCommand("jump", self.jump)
  self:AddChatCommand("togglejump", self.toggleJump)
  --Command Alias
  self:AddChatCommand("goto", self.jump)
  --grab our raw file
  self.conf = util.GetDatafile("s3ctor")
  --give ourselves a safe default of an empty table
  self.access = {}
  --load our file into a blob
  local blob = self.conf:GetText()
  --if we have something, decode it
  if blob ~= nil and blob ~= "" then
    self.access = json.decode(blob)
  end

end

--save our config file after changes
function PLUGIN:save()
  --  if self.access ~= nil then
  --  self.conf:setText(json.encode(self.access))
  --  self.conf:save()
  --  end
end

--Add a new jump point
function PLUGIN:setJump(netuser, cmd, args)
  --admin check
  if netuser:CanAdmin() then
    --[[
      So, weirdness here:
      It's possible that we don't have a known position. Which is weird. Moreso,
      we can't just treat it like a boolean truthy operator. So, instead,
      we need to use hasLastKnownPosition and then grab the position.
    ]]
    if netuser.playerClient.hasLastKnownPosition then
  		local curloc = netuser.playerClient.lastKnownPosition
      --check that we have our arg
      if args[1] then
        --give ourselves a clean table for our new entry
        local entry = {}
        --save coords
        entry.coords = curloc
        --disabled by default
        entry.enabled = 0
        --save it to our access table under the location name
        self.access[args[1]] = entry
        --save our access table
        self.save()
        --let them know
        rust.Notice(netuser, "Jump Created!");
      else
        rust.Notice(netuser, "Usage: /setjump [name]")
      end
    else
      rust.Notice(netuser, "Can't get your position!")
    end
  else
    rust.Notice(netuser, "This command is restricted to Admins")
  end
end

--lets run a teleport
function PLUGIN:jump(netuser, cmd, args)
  -- rust.ServerManagement():TeleportPlayer( netuser.playerClient.netPlayer, coords)
  --make sure we have a location
  if args[1] then
    --save our location name
    local location = self.access[args[1]]
    --if we have the location and it's enabled
    if location and location.enabled > 0 then
      rust.Notice(netuser, "Teleporting you in 40 seconds")
      --create a one-off timer with an anonymous function
      timer.Once(40, (
          function()
            --[[
            CRAZYNESS: Our player might disconnect before we TP, but the netuser
            will persist. There's jack we can do about it, so run the command and hope for the best.
            ]]
            rust.ServerManagement():TeleportPlayer( netuser.playerClient.netPlayer, location.coords)
          end
      ))
    else
      rust.Notice(netuser, "That location does not exist or is disabled")
    end
  else
    rust.Notice(netuser, "Please use the format /goto location")
  end

end

--Toggle whether a jump point is active or not
function PLUGIN:toggleJump(netuser, cmd, args)
  --admins only
  if netuser:CanAdmin() then
    --we have a location
    if args[1] then
      --pull the location entry in the access table
      local location = self.access[args[1]]
      if location then
        --invert the value
        if location.enabled > 0 then
          self.access[args[1]].enabled = 0
          rust.Notice(netuser, "Location Disabled")
        else
          self.access[args[1]].enabled = 1
          rust.Notice(netuser, "Location Enabled")
        end
        --update our table
        self.save()
      else
        rust.Notice(netuser, "Location not found")
      end
    else
      rust.Notice(netuser, "Usage: /togglejump location")
    end
  else
    rust.Notice(netuser, "This command is restricted to Admins")
  end
end

--Provides help commands to the Advanced Help plugin by Friendly Ape
function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "/gotohelp   (Shows all teleport locations)");
	rust.SendChatToUser( netuser, "/goto LocationName   (Teleports you to a location)");
end
