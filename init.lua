---Class representing the module
---@class chatcommands
local exports = {}

local imports = {
  argparse = require("vendor.argparse"),
  tokenize = require("tokenize").tokenize,
}

local COMMAND_REGISTRY = {}

local startsWith = function(s, start)
    return string.sub(s, 1, string.len(start)) == start
end

local onChatCommand = function(chatMessage)

    local handled = false

    for command, handler in pairs(COMMAND_REGISTRY) do
      if startsWith(chatMessage, "/" .. tostring(command)) and handled == false then
        handled = true
        local args = imports.tokenize(chatMessage)
        table.remove(args, 1)
        local success, keepModalOpen, newMessage = pcall(handler, args, chatMessage)

        if not success then
          local msg = "[commands]: error in processing command: " .. tostring(chatMessage) .. "\nerror: " .. tostring(keepModalOpen)
          log(WARNING, msg)
          return false, msg
        else
          if not keepModalOpen then
            return false, newMessage
          else
            return true, newMessage
          end
        end

      end
    end

    if not handled then
        local text = "Unknown command: " .. tostring(chatMessage)
        
        return false, text
    end

    error("we should never get here")
end


-- namespace


function exports.enable(self, config)
  self.COMMAND_REGISTRY = COMMAND_REGISTRY

  modules.chat:registerChatHandler("/", onChatCommand)

  self:registerChatCommand("help", function(args, command)
      log(2, "Processing command: " .. tostring(command))
      local commands = {}
      for k, v in pairs(COMMAND_REGISTRY) do
          table.insert(commands, k)
      end
      table.sort(commands)
      local result = ""
      for k, command in pairs(commands) do
          result = result .. ", " .. command
      end
      return false, "available commands: " .. result
  end)

  return true
end

function exports.disable(self, config)
    
end

local function stringSplit(s, sep)
  local sep, fields = sep or " ", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[#fields+1] = c end)
  return fields
end

---Register a chat command callback which is called upon
---a chat message with that command
---@param self table Self
---@param command string|table The command name to register without the "/" prefix, or an argparse object (includes "/" prefix)
---@param callback fun(args: table, command: string):boolean, string Callback function called
---upon command. Should return two values: whether to keep the chat modal open (boolean), and an optional
---new message in the form of a string. Note that the args parameter in the callback can be an argparse result object
---@return void
function exports.registerChatCommand(self, command, callback)
  local commandString = command
  local commandCallback = callback

  if type(command) == "table" then
    -- argparse object
    local ap = command
    commandString = ap._name
    if commandString:sub(1,1) == "/" then
      commandString = commandString:sub(2)
    end

    commandCallback = function(args, cmd)
      local success, result = ap:parse(args)      
      if not success then
        local err = result
        if type(err) == "string" then
          error(err) --reraise
        end

        if err.status == "help" then
          log(INFO, cmd)
          log(INFO, "\n" .. tostring(err.message))
          --TODO: make the usage fit in the Crusader window
          --so that Commands actually fit
          --local messages = stringSplit(err.message, "\n\n")
          return false, err.usage
        elseif err.status == "error" then
          return false, {err.message, err.usage}       
        else
          error(string.format("unknown error status: %s", err.status))   
        end

      end

      return callback(result, cmd)
    end
  end

  if COMMAND_REGISTRY[commandString] ~= nil then
    error("Failed to register command. Command was already registered: " .. tostring(commandString))
  end
  COMMAND_REGISTRY[commandString] = commandCallback

  log(1, "Registered command: " .. tostring(commandString))
end

---Untested
---Returns a new Parser from the argparse lua library.
---Make sure to call pparse() instead of parse() to avoid exiting Crusader.
---https://github.com/mpeterv/argparse
---@param self table Self
---@param ... any Arguments passed to the initialization function Parser
---@return table The parser as defined in argparse
function exports.argparser(self, ...)
  return imports.argparse(...)
end

return exports, {
  proxy = {
    ignored = {
      "argparser",
    },
  },
}