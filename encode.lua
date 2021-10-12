package.path="/usr/local/openresty/lualib/?.lua"

-- 收到原地址后转为短链
-- 引入包
local pg_utils = require "urlshortener.pg_utils"
local base62generator = require "urlshortener.lua-base62-encode"

-- 常量定义
local config = require "urlshortener.config.const"
local base_url = config.prefix.base_url
local pg = pg_utils:pg_connect()
local shorten_url = nil

local function isempty(s)
  return s == nil or s == '' or s == "null" or (type(s) == "boolean" and not s) or s == ngx.null
end

-- 检查header头
local check_ret = false
local token = ngx.req.get_headers()[config.token_name]
ngx.log(ngx.DEBUG, "shortener token is " .. token)
if not isempty(token)  then
	for _,v in pairs(config.tokens) do
		if v == token then
			check_ret = true
			break
		end
	end
else
	ngx.log(ngx.ERR, "token empty, host is : " .. ngx.req.get_headers()["host"])
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end
if check_ret == false then
	ngx.log(ngx.ERR, "token check failed, host is : " .. ngx.req.get_headers()["host"])
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ret = {}

-- 参数获取
ngx.req.read_body()
local args, err = ngx.req.get_body_data()
if not args then
    ngx.log(ngx.ERR, "failed to get post args: ", err)
    return
end
local cjson = require "cjson"
local jargs = cjson.decode(args)
local request_url = jargs["url"]
local md5ret = ngx.md5(request_url)
-- local md5_key = config.prefix.md5_k_prefix .. md5ret
ngx.log(ngx.DEBUG,  "checking md5 key " .. md5ret) 
local res,err = pg_utils:check_url_exists(pg, md5ret)
-- local ok, err = redis_cli:exists(md5_key)
ngx.log(ngx.DEBUG, "!!!!!!!")
if res ~= false then
	-- 已有对应短链
	pg:keepalive()
	local shorten_url = res
	ret.data = base_url .. "/" .. shorten_url
	ret.httpcode = ngx.HTTP_OK
	local jret = cjson.encode(ret)
	ngx.header.content_type = "application/json; charset=utf-8"  
        ngx.log(ngx.DEBUG, "!!!!!!!")
	ngx.say(jret)
	ngx.exit(ngx.HTTP_OK)
elseif err ~= nill then
	-- 有报错
	ngx.log(ngx.ERR, "Failed to get exists shortener, ERROR: "..err)
	pg:keepalive()
	ngx.exit(500)
else
	-- 获取sequence
	local s_id = pg_utils:get_sequence(pg)
	if s_id == nil then
		ngx.log(ngx.ERR, "Failed to get sequence, shortener exit")
		pg:keepalive()
		ngx.exit(500)
	end
	-- 制作base62
	local b62 = base62generator:encode(s_id)
	if b62 ~= nil then
		ngx.log(ngx.DEBUG, "b62 got")
		shorten_url = config.prefix.base_url .. "/" .. b62
		local b62_key = config.prefix.b62_k_prefix .. b62
		ngx.log(ngx.DEBUG, "setting md5-baseurl")
		local res = pg_utils:insert_shorturl(pg, request_url, md5ret, b62)
                if res then
                    pg:keepalive()
		    ret.data = shorten_url
		    ret.httpcode = ngx.HTTP_OK
		    local jret = cjson.encode(ret)
		    ngx.header.content_type = "application/json; charset=utf-8"  
		    ngx.say(jret)
		    ngx.exit(ngx.HTTP_OK)
                else
                    ngx.log(ngx.ERR, "Failed to insert shorten url")
                    pg:keepalive()
                    ngx.exit(500)
                end
	end

end

