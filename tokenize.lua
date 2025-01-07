
local function tokenize(s)
  local tokens = {}

  local character = ""
  local token = ""
  local is_quoting = false
  local quoting_char
  local i = 1
  while i <= s:len() do
    character = s:sub(i, i)
    if character == "" then
      break
    elseif character == " " then
      if is_quoting then
        token = token .. character
      else
        table.insert(tokens, token)
        token = ""
      end
    elseif character == '"' or character == "'" then
      if quoting_char == nil then
        quoting_char = character
      end
      if quoting_char ~= character then
        error(string.format("Mixing of quotation marks is not supported: '%s'", s))
      end
      if is_quoting then
        is_quoting = false
      else
        is_quoting = true
      end
      token = token .. character
    else
      token = token .. character
    end

    i = i + 1
  end

  if is_quoting then
    error(string.format("Missing ending quotation mark: %s", s))
  end

  if token:len() > 0 then
    table.insert(tokens, token)
  end

  return tokens
end

return {
  tokenize = tokenize,
}