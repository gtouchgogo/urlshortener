local _M = {}
function _M:encode(number)
  local base = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local index = number % 62 + 1
  local result = base:sub(index, index)
  local quotient = math.floor(number / 62)
  while quotient ~= 0 do
    index = quotient % 62 + 1
    quotient = math.floor(quotient / 62)
    result = base:sub(index, index) .. result
  end
  print("base62 result: " .. result)
  return result
end
return _M


