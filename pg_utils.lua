package.path = "/usr/local/openresty/lualib/?.lua"
package.path = "/usr/local/openresty/site/lualib/?.lua;" .. package.path
local pgmoon = require("pgmoon")

local encode = require "cjson" .encode

local _M = {}

-- 链接db，使用pool保持连接
function _M:pg_connect()
    local pgmoon = require("pgmoon")
    local config = require("urlshortener.config.db_config")

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
    return pg
end

-- 根据url的md5查询是否已有短链，有则返回，无则返回false
function _M:check_url_exists(pg, raw_url)
    local raw = pg:escape_literal(raw_url)
    local result, err, num_queries =
         pg:query("select url_b62 as url from url_shortener where is_valid = True and url_md5 = " .. raw)
    if result ~= nil then
        if #result > 0 then
            return result[1]["url"]
        else
            return false
        end
    else
        if err then
            ngx.log(ngx.ERR, "Failed to check url exists in shortener" .. err)
        else 
            ngx.log(ngx.ERR, "Failed to check url exists in shortener")
        end
    end
end

-- 获取最新的id
function _M:get_sequence(pg)
    local result, err, num_queries = pg:query("SELECT id FROM url_shortener ORDER BY ID DESC LIMIT 1")
    if result ~= nil then
        ngx.log(ngx.DEBUG, "result is " .. encode(result))
        ngx.log(ngx.DEBUG, "err is " .. encode(err))
        if #result > 0 then
            local lid = result[1]["id"]
            return tonumber(lid) + 1
        else
        -- 无数据
            if err ~= 1 then
                ngx.log(ngx.ERR, "Failed to get latest sequence " .. err)
                return nil
	    else
                return 1
            end
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
    local raw = pg:escape_literal(url_raw)
    local md5 = pg:escape_literal(url_md5)
    local b62 = pg:escape_literal(url_b62)
    local result, err, num_queries =
        pg:query(
        "INSERT INTO public.url_shortener(url_raw, url_md5, url_b62) \
        VALUES (" .. raw .. ", ".. md5 ..", ".. b62 .. ") RETURNING id"
    )
    ngx.log(ngx.DEBUG, "result " .. encode(result))
    ngx.log(ngx.DEBUG, "err" .. encode(err))
    if result ~= nil then
        ngx.log(ngx.INFO, "Success insert shortener " .. url_raw .. "to" .. url_b62)
        return true
    else
        if err ~= 1 then
            ngx.log(ngx.ERR, "Failed to insert shortener " .. url_raw .. "Error: " .. err)
        end
        return false
    end
end

-- 解码
function _M:get_raw_url(pg, url_b62)
    local b62 = pg:escape_literal(url_b62)
    local result, err, num_queries =
        pg:query(
        "SELECT url_raw as raw FROM public.url_shortener WHERE url_b62 = " .. b62
    )
    if result ~= nil then
        if #result > 0 then
            ngx.log(ngx.INFO, "Success decode shortener " .. url_b62 .. "to" .. encode(result))
            return result[1]["raw"]
        else
            return nil
        end
    else
        ngx.log(ngx.ERR, "Failed to decode shortener " .. url_b62 .. "Error: " .. err)
        return nil
    end
end
return _M
