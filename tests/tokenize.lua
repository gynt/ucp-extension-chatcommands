local tokenize = require("tokenize")

local function result_string(args)
  local s = ""
  for k, v in pairs(args) do
    s = s .. string.format("%s  %s\n", k, v)
  end
  return s
end

local a = tokenize("/test dump 'a b c sde1290' --help1 --set 2 arg, v")
local a_expected = [[
1  /test
2  dump
3  'a b c sde1290'
4  --help1
5  --set
6  2
7  arg,
8  v
]]

if a_expected ~= result_string(a) then
  error(string.format("test A failed: \nExpected:\n%s\n\nReceived:\n%s", a_expected, result_string(a)))
end

local b = tokenize('/test dump "a b c sde1290" --help1 --set 2 arg, v')
local b_expected = [[
1  /test
2  dump
3  "a b c sde1290"
4  --help1
5  --set
6  2
7  arg,
8  v
]]

if b_expected ~= result_string(b) then
  error("test B failed")
end

return true