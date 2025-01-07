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

  self:registerChatCommand("help", function(command)
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

---Register a chat command callback which is called upon
---a chat message with that command
---@param self table Self
---@param commandName string The command name to register without the "/" prefix
---@param commandCallback fun(args: table, command: string):boolean, string Callback function called
---upon command. Should return two values: whether to keep the chat modal open (boolean), and an optional
---new message in the form of a string.
---@return void
function exports.registerChatCommand(self, commandName, commandCallback)
  if COMMAND_REGISTRY[commandName] ~= nil then
    error("Failed to register command. Command was already registered: " .. tostring(commandName))
  end
  COMMAND_REGISTRY[commandName] = commandCallback

  log(1, "Registered command: " .. tostring(commandName))
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