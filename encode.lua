package.path="/usr/local/openresty/nginx/startalk_lua/?.lua"
-- 收到原地址后转为短链
local redis = require "urlshortener.redis_utils"
local base62generator = require "urlshortener.lua-base62-encode"

-- 常量定义
local config = require "urlshortener.config.const"

local redis_cli = redis:redis_connect()

local shorten_url = nil

local function isempty(s)
  return s == nil or s == '' or s == "null" or (type(s) == "boolean" and not s) or s == ngx.null
end

-- 检查header头
local check_ret = false
local token = ngx.req.get_headers()[config.token_name]
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
local md5_key = config.prefix.md5_k_prefix .. md5ret
ngx.log(ngx.DEBUG,  "checking md5 key " .. md5_key) 
	
local ok, err = redis_cli:exists(md5_key)
ngx.log(ngx.DEBUG, "checking result: " .. ok)
ngx.log(ngx.DEBUG, "checking result: " .. type(ok))
if not err and ok ~= 0 then
	shorten_url = redis_cli:get(md5_key)
	ret.data = shorten_url
	ret.httpcode = ngx.HTTP_OK
	local jret = cjson.encode(ret)
	ngx.header.content_type = "application/json; charset=utf-8"  
	ngx.say(jret)
	ngx.exit(ngx.HTTP_OK)
else
	if err then
		ngx.log(ngx.ERR, "error check exists", err)
	end
	-- 获取sequence 制作短链接
	local s_id, err = redis_cli:get(config.prefix.k_s_id)	
	local test = isempty(s_id)
        local b62 = nil
	if not isempty(s_id) then
		-- 制作base62
	        b62 = base62generator:encode(s_id)
	else
		if err then
			ngx.log(ngx.ERR, "faild to get sequence id " .. err)
		end
                -- 插入sequence id 
		s_id = 1
		local ok, err = redis_cli:set(config.prefix.k_s_id, s_id)
		if err then
			ngx.log(ngx.ERR, "failed to insert new sequence id" .. err)
		else
			b62 = base62generator:encode(s_id)
		end
	end

        if b62 ~= nil then
                ngx.log(ngx.DEBUG, "b62 got")
		shorten_url = config.prefix.base_url .. "/" .. b62
		local b62_key = config.prefix.b62_k_prefix .. b62
                -- maybe need expire time
                ngx.log(ngx.DEBUG, "setting md5-baseurl")
		redis_cli:set(md5_key, shorten_url, "ex", config.exp_time)
                ngx.log(ngx.DEBUG, "setting shorturl-baseurl")
		redis_cli:set(b62_key, request_url, "ex", config.exp_time)
                ngx.log(ngx.DEBUG, "increasing sequence id")
		redis_cli:incr(config.prefix.k_s_id)
		ret.data = shorten_url
		ret.httpcode = ngx.HTTP_OK
		local jret = cjson.encode(ret)
		ngx.header.content_type = "application/json; charset=utf-8"  
		ngx.say(jret)
		ngx.exit(ngx.HTTP_OK)

	else
		ngx.log(ngx.ERR, "failed to get b62 result" .. err)
	end
end

