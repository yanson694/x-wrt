require("iw-uci")
require("iwuci")

parser = {}
local P = {}
parser = P
-- Import Section:
-- declare everything this package needs from outside
local io = io
local wwwprint = wwwprint
if wwwprint == nil then wwwprint=print end
local oldprint = oldprint
local table = table
local type = type
local string = string
local pairs = pairs
local iwuci = iwuci
local uciClass = uciClass
local tonumber = tonumber

local freeradius = uciClass.new("freeradius")
-- no more external access after this point
setfenv(1, P)

enable    = tonumber(freeradius.webadmin.enable)    or 0
userlevel = tonumber(freeradius.webadmin.userlevel) or 0
reboot    = false                -- reboot device after all apply process

name = "Freeradius Clients"
script = "radiusd"
init_script = "/etc/init.d/radiusd"

function process()
  wwwprint("Committing freeradius_clients...")
  iwuci.commit("freeradius_clients")
  local freeradius = uciClass.new("freeradius")
--  if freeradius.webadmin.service == "0" then
    wwwprint(name.." clients... Parsers...")
  -- Process clients.conf
    local sep = ""
    local clients = uciClass.new("freeradius_clients")
    local client_str = ""
    for i=1, #clients.client do
      client_str = client_str .. "client "..clients.client[i].values.client.." {\n"
      sep = "\t"
      for k,v in pairs(clients.client[i].values) do
        if k ~= "client" then
          client_str = client_str..sep..k.."\t= "..v
          sep = "\n\t"
        end
      end
      client_str = client_str.."\n}\n"
    end

    local pepe = io.open("/etc/freeradius/clients.conf","w")
    pepe:write(client_str)
    pepe:close()
--  end
end
