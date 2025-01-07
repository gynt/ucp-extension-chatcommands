local CommandParser = require("CommandParser")
local parser = CommandParser:init()

parser:command_target("command")
parser:command("hello")
parser:command("world")

local args = parser:parse("hello")