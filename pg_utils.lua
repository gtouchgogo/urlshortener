package.path = "/usr/local/openresty/nginx/startalk_lua/?.lua"
local pgmoon = require("pgmoon")

local _M = {}

-- 链接db，使用pool保持连接
function _M:pg_connect()
    local pgmoon = require("pgmoon")
    local config = require("urlshortener.config.pg_config")

    local pg =
        pgmoon.new(
        {
            host = config.pg.host,
            port = config.pg.port,
            database = config.pg.database,
            user = config.pg.user,
            password = config.pg.passwd,
            pool_size = 10
        }
    )
    pg:settimeout(config.pg.timeout)
    --connect pg ok
    assert(pg:connect())
    pg:keepalive()

    if ok then
        ok, err = redis_cli:auth(config.redis.passwd)
        redis_cli:select(tonumber(config.redis.subpool))
        if ok then
            --auth redis ok
            return redis_cli
        else
            ngx.log(ngx.ERR, "e " .. "redis auth failed: " .. err)
            return nil
        end
    else
        ngx.log(ngx.ERR, "e " .. "redis connct failed: " .. err)
        return nil
    end
end

-- 根据url的md5查询是否已有短链，有则返回，无则返回false
function _M:check_url_exists(pg, raw_url)
    local raw = pg:escape_literal(raw_url)
    local result, err, num_queries =
        pg:query("select url_b62 as url from url_shortener where is_valid = True and url_md5 = $1", raw)
    if result ~= nil then
        ngx.log(ngx.DEBUG, "Checking exists result " .. result)
        if #result > 0 then
            return result[1]["url"]
        else
            return false
        end
    else
        ngx.log(ngx.ERR, "Failed to check url exists in shortener" .. err)
    end
end

-- 获取最新的id
function _M:get_sequence(pg)
    local result, err, num_queries = pg:query("SELECT id FROM url_shortener ORDER BY ID DESC LIMIT 1")
    if result ~= nil then
        ngx.log(ngx.DEBUG, "Get latest id from shortener result " .. result)
        if #result > 0 then
            local lid = result[1]["id"]
            return tonumber(lid) + 1
        else
            if err then
                ngx.log(ngx.ERR, "Failed to get latest sequence " .. err)
                return nil
            end
            return 1
        end
    else
        if err then
            ngx.log(ngx.ERR, "Failed to get latest sequence " .. err)
            return nil
        end
        return 1
    end
end

-- 插入短链
function _M:insert_shorturl(pg, url_raw, url_md5, url_b62)
    local raw = pg:escape_literal(raw_url)
    local md5 = pg:escape_literal(url_md5)
    local b62 = pg:escape_literal(url_b62)
    local result, err, num_queries =
        pg:query(
        "INSERT INTO public.url_shortener(url_raw, url_md5, url_b62) \
        VALUES ($1, $2, $3) RETURNING id",
        raw,
        md5,
        b62
    )
    if result ~= nil and err == nil then
        ngx.log(ngx.INFO, "Success insert shortener " .. url_raw .. "to" .. url_b62)
        return true
    else
        ngx.log(ngx.ERR, "Failed to insert shortener " .. url_raw .. "Error: " .. err)
        return false
    end
end

-- 插入短链
function _M:get_raw_url(pg, url_b62)
    local b62 = pg:escape_literal(url_b62)
    local result, err, num_queries =
        pg:query(
        "SELECT url_raw as raw FROM public.url_shortener WHERE ",
        raw,
        md5,
        b62
    )
    if result ~= nil and err == nil then
        ngx.log(ngx.INFO, "Success insert shortener " .. url_raw .. "to" .. url_b62)
        return true
    else
        ngx.log(ngx.ERR, "Failed to insert shortener " .. url_raw .. "Error: " .. err)
        return false
    end
end
return _M
