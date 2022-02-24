package.path="/usr/local/openresty/nginx/startalk_lua/?.lua";
local ckeyChecker = require("checks.qim.ckeycheck")


local _M = {}
function _M:redis_connect()
        local redis = require "resty.redis"
        local config = require("urlshortener.config.redis_config")
	local redis_cli = redis:new()
	redis_cli:set_timeout(500)
        local  ok, err = redis_cli:connect(config.redis.host, config.redis.port)
        --connect redis ok
        if ok then
            ok, err = redis_cli:auth(config.redis.passwd)
            redis_cli:select(tonumber(config.redis.subpool))
            if ok then
		--auth redis ok
		return redis_cli;
            else
		ngx.log(ngx.ERR,"e " .. "redis auth failed: " .. err)
                return nil;
            end
        else
		ngx.log(ngx.ERR,"e " .. "redis connct failed: " .. err)
		return nil;
        end
end
return _M
