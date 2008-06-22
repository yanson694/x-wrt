require("uci")
local www_print = print
if __WWW then
    www_print = function (x)
    return print(x,"<br>")
    end
end
-- Customized uci functions --
uci_save = uci.save
uci_commit = uci.commit

uci.save = function (x)
  local ret
  if x == nil then 
    ret = uci_save()
  else
    ret = uci_save(x)
  end
  return ret
  end

uci.commit = function (x)
  local ret = false
  if x == nil then
    ret = uci_commit()
  else
    ret = uci_commit(x)
  end
  if ret == true then
    www_print (x.." ".."Commited OK!")
    os.execute("rm /tmp/.uci/"..x.." 2> /dev/null")
  end
  return ret
  end

-- Added uci functions --
function uci.get_all_types(p)
  local sections = {}
  local found = false
  p = uci.get_all(p)
  for i, v in pairs(p) do
    if sections[v[".type"]] == nil then sections[v[".type"]] = {} end
    sections[v[".type"]][#sections[v[".type"]]+1] = {}
    found = true
    for k, o in pairs(v) do
      sections[v[".type"]][#sections[v[".type"]]][k] = o
    end
  end
  if found == true then
    return sections
  else
    return nil
  end
end

function uci.get_type(p,s)
  local sections = {}
  local found = false
  if string.find(p,".") > 0 and s == nil then
    p,s = unpack(string.split(p,"."))
  end
  p = uci.get_all(p)
  for i, v in pairs(p) do
    if v[".type"] == s then
      sections[#sections+1] = {}
      found = true
      for k, o in pairs(v) do
        sections[#sections][k] = o
      end
    end
  end
  if found == true then
    return sections
  else
    return nil
  end
end

function uci.get_section(p,s)
  local t = uci.get_all(p)
  return t[s]
end

function uci.updated()
  local mycount = 0
	local BUFSIZE = 2^13     -- 8K
	assert(os.execute("mkdir /tmp/.uci > /dev/null 2>&1"))
	local filelist = assert(io.popen("ls /tmp/.uci")) 
	for filename in filelist:lines() do
		local f = io.input("/tmp/.uci/"..filename)   -- open input file
		while true do
			local lines, rest = f:read(BUFSIZE, "*line")
			if not lines then break end
			if rest then lines = lines .. rest .. '\n' end
			for li in string.gmatch(lines,"[^\n]+") do
        mycount = mycount + 1
			end
		end
	end
  return mycount
end
   