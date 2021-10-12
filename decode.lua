package.path="/usr/local/openresty/lualib/?.lua"

-- 收到短链转换原本
local config = require "urlshortener.config.const"
local pg_utils = require "urlshortener.pg_utils"
local pg = pg_utils:pg_connect()

local function isempty(s)
  return s == nil or s == '' or s == "null" or (type(s) == "boolean" and not s) or s == ngx.null
end

-- local b62 = config.prefix.b62_k_prefix .. ngx.var.request_uri:gsub("%/","")
local b62 = ngx.var.last_path_component
local url, err = pg_utils:get_raw_url(pg, b62)
if isempty(url) or url == nil then
	if err then
		ngx.log(ngx.ERR, "failed to get origin url" .. e)
	end
	ngx.exit(ngx.HTTP_BAD_REQUEST)
else
        ngx.log(ngx.INFO, "shorten url: " .. b62 .. " origin url: " .. url)
	ngx.redirect(url, 301);
end
