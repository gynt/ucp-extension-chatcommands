local exports

local COMMAND_REGISTRY = {}

local startsWith = function(s, start)
    return string.sub(s, 1, string.len(start)) == start
end

local onChatCommand = function(chatMessage)

    local handled = false

    for command, handler in pairs(COMMAND_REGISTRY) do
      if startsWith(chatMessage, "/" .. tostring(command)) and handled == false then
        handled = true
        local success, keepModalOpen, newMessage = pcall(handler, chatMessage)

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


exports = {
    enable = function(self, module_options, global_options)
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
    end,

    disable = function(self)
        return false, "not implemented"
    end,

    registerChatCommand = function(self, commandName, commandCallback)
      if COMMAND_REGISTRY[commandName] ~= nil then
        error("Failed to register command. Command was already registered: " .. tostring(commandName))
      end
      COMMAND_REGISTRY[commandName] = commandCallback

      log(1, "Registered command: " .. tostring(commandName))
    end
}

return exports