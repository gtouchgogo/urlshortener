local _M = {}
_M.token_name = "bz-token" -- 请求转短链时需要header上带这个头
_M.tokens = {"XXXXXXXXXXXX"} -- 上面属性token_name允许的值，可以有多个
_M.exp_time = 2592000 -- redis过期时间，即短链保存一个月，pg存储不需要
_M.prefix = {}
_M.prefix.base_url = "https://YOUR_SHORT_DOMAIN" -- 换成自己的短链域名
-- 以下三项如使用pg存储不需要配置
_M.prefix.md5_k_prefix = "us_" -- redis中的原始url md5后的prefix
_M.prefix.b62_k_prefix = "b62_" -- redis中字增id b62后的prefix
_M.prefix.k_s_id = "us_sid"  --  redis中字增id的prefix

return _M

