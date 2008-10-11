require("uci_iwaddon")
require("common")

parser = {}
local P = {}
parser = P
-- Import Section:
-- declare everything this package needs from outside
local wwwprint = wwwprint
if wwwprint == nil then wwwprint=print end
local ipcalc = ipcalc
local uci = uci
local io = io
local string = string
local oldprint = oldprint
local table = table
local pairs = pairs
local tonumber = tonumber
-- no more external access after this point
setfenv(1, P)

name = "Coovachilli"
script = "chilli"
init_script = "/etc/init.d/chilli"

enable = tonumber(uci.get("coovachilli.webadmin.enable")) or 0
local userlevel = tonumber(uci.get("coovachilli.webadmin.userlevel")) or 0
local radiususers = tonumber(uci.get("coovachilli.webadmin.radconf")) or 0
call_parser = "freeradius freeradius_check freeradius_clients freeradius_proxy"

reboot = false                -- reboot device after all apply process
--exe_before = {} -- execute os process in this table before any process
exe_after  = {} -- execute os process after all apply process
if radiususers > 1 then
  exe_after["/etc/init.d/radiusd restart"]="freeradius"
end
--depends_pkgs = "libltdl freeradius freeradius-mod-files freeradius-mod-chap freeradius-mod-radutmp freeradius-mod-realm iw-freeradius"
exe_after["/etc/init.d/network restart"]="network"
exe_after["wifi"]="wifi"


function process()
  radiususers = tonumber(uci.get("coovachilli.webadmin.radconf")) or 0
  t = ipcalc(uci.get("coovachilli","uam","HS_UAMLISTEN"),uci.get("coovachilli","net","HS_NETMASK"))
  uci.set("coovachilli","net","HS_NETWORK",t["NETWORK"])
  if radiususers > 1 then
    wwwprint("Checking freeradius installation")
    local write_file
    if io.exists("/usr/share/freeradius/dictionary") then
      local dict = io.totable("/usr/share/freeradius/dictionary",true)
      wwwprint("Updating /usr/share/freeradius/dictionary")
      if dict[1] ~= "$INCLUDE dictionary.chillispot" then
        table.insert(dict,1,"$INCLUDE dictionary.chillispot")
      end
      write_file = io.open("/usr/share/freeradius/dictionary","w")
      write_file:write(table.concat(dict,'\n'))
      write_file:close()
    end
  end
  if uci.get("coovachilli.webadmin.ifwifi") and uci.get("coovachilli.net.HS_LANIF") == nil then
    uci.check_set("network","wifi","interface")
    uci.set("network","wifi","proto","static")
    uci.set("network","wifi","type","bridge")
--    uci.save("network")
    if uci.get("network.wifi.ifname") == nil then
      uci.set("network","wifi","ifname",uci.get("coovachilli.webadmin.ifwifi"))
    elseif not string.gmatch(uci.get("network.wifi.ifname"),uci.get("coovachilli.webadmin.ifwifi")) then
      uci.set("network","wifi","ifname", uci.get("network.wifi.ifname").." "..uci.get("coovachilli.webadmin.ifwifi"))
    end
--  uci.set("network",set_netname,"dns","204.225.44.3")
    uci.save("network")
    local network = uci.get_all("network")
    if network.wifi.type ~= "bridge" then
      if network.wifi.ifname ~= nil then
        uci.set("coovachilli","net","HS_LANIF",network.wifi.ifname)
      end
    else
      uci.set("coovachilli","net","HS_LANIF","br-wifi")
    end
    uci.save("coovachilli")
  end
  local network = uci.get_all("network")
  if uci.get("coovachilli","webadmin","enable") == "1" then
    local wififace = uci.get_type("wireless","wifi-iface")
    for i=1, #wififace do
      if wififace[i].device == network.wifi.ifname then
--        uci.set("wireless",wififace[1][".name"],"ssid","X-Wrt")
--        uci.set("wireless",wififace[1][".name"],"network","wifi")
        uci.set("wireless",network.wifi.ifname,"disabled","0")
        break
      end
    end
  else
    uci.set("wireless",network.wifi.ifname,"disabled", "0")
  end    
  uci.commit("network")
  uci.commit("wireless")
  uci.commit("coovachilli")
  write_init()
  write_config()
end


function write_init()
  wwwprint ("Writing init file /etc/init.d/chilli")
  local init_file = [[#!/bin/sh /etc/rc.common
START=59

EXTRA_COMMANDS="status checkrunning radconfig condrestart"
EXTRA_HELP="	status	Show current status
    checkrunning If services is not running start it"

PATH=/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/chilli
NAME=chilli
DESC=chilli
CONFFILE=/etc/chilli.conf
OPTS="--pidfile /var/run/$NAME.pid"

. /etc/chilli/functions
check_required

start() {
	echo -n "Starting $DESC: "
   /sbin/modprobe tun >/dev/null 2>&1
   echo 1 > /proc/sys/net/ipv4/ip_forward

   writeconfig
   radiusconfig

   (crontab -l 2>&- | grep -v $0
      test ${HS_ADMINTERVAL:-0} -gt 0 && echo "*/$HS_ADMINTERVAL * * * * $0 radconfig"
      echo "*/10 * * * * $0 checkrunning"
      #echo "*/2  * * * * $0 arping"
   ) | crontab - 2>&-
  $DAEMON -- $OPTS
  RETVAL=$?
	echo "$NAME."
}

status () {
		pid=$(cat "/var/run/$NAME.pid" 2>/dev/null)
		[ -n "$pid" -a -d "/proc/$pid" ] && {
      echo "$DESC running"
      exit 0
		}
    echo "$DESC stopped"
}

checkrunning () {
    local pid
		pid=$(cat "/var/run/$NAME.pid" 2>/dev/null)
		[ -n "$pid" -a -d "/proc/$pid" ] && {
			exit 0
		}
    $0 start
}

radconfig () {
      [ -e $MAIN_CONF ] || writeconfig
      radiusconfig
}

stop () {
    local pid
		pid=$(cat "/var/run/$NAME.pid" 2>/dev/null)
		[ -n "$pid" -a -d "/proc/$pid" ] && {
      echo -n "Stopping $DESC: "
      crontab -l 2>&- | grep -v $0 | crontab -
      kill -TERM "$pid"
      [ "$?" -eq 0 ] && sleep 1
      [ ! -d "/proc/$pid" ] && echo "OK" || {
  			echo "Failed!"
        echo -n "Killing chilli..."
        kill -KILL "$pid"
        [ "$?" -eq 0 ] && echo "OK" || echo "Failed!"
      }
      exit 0
		}
		echo "$DESC was not running"
}

condrestart() {
    local pid
		pid=$(cat "/var/run/$NAME.pid" 2>/dev/null)
		[ -n "$pid" -a -d "/proc/$pid" ] && {
      echo -n "Restarting $DESC: "
      $0 restart
      RETVAL=$?
		}
}
]]
  write_file = io.open("/etc/init.d/chilli","w")
  write_file:write(init_file)
  write_file:close()
  wwwprint("/etc/init.d/chilli writed OK!")
end

function write_config()
  wwwprint ("Writing configuration file /etc/chilli/config")
  local coovadir = uci.get_type("coovachilli","coovadir")
  local str_set="#### This conf file was writed by iw-apply for coova ####\n"
  for x,y in pairs(coovadir) do
    for k, v in pairs(y) do
      if k ~= ".type"
      and k ~= ".name" then
        str_set = str_set..k.."="..v.."\n"
      end
    end
  end
  local chillisettings = uci.get_type("coovachilli","settings")
  for x,y in pairs(chillisettings) do
    for k, v in pairs(y) do
      if k ~= ".type"
      and k ~= ".name" then
        if string.match(v,"%s") then v = "\""..v.."\"" end
        str_set = str_set..k.."="..v.."\n"
      end
    end
  end
  write_file = io.open("/etc/chilli/config","w")
  write_file:write(str_set)
  write_file:close()
  wwwprint("/etc/chilli/config writed OK!")
end

return parser
