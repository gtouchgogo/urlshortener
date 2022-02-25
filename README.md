

### 短链服务
#### 前提
1. 因为服务是使用lua编写的nginx插件所以需要OpenResty
2. 使用redis存储需要用到 resty.redis https://github.com/openresty/lua-resty-redis （OR默认自带，如果没有需要装一下)

#### 部署
1. 将整个文件夹拷贝到 nginx下的lua文件夹
2. nginx.conf 添加路由
在转短链的server下添加
```
location /shortener.star{
    rewrite_by_lua_file /PATH/TO/NGINX/LUA/urlshortener/encode.lua;
}
```
在短链的server下添加 (path以 /zsd 为例)
```
location /zsd {
    if ($request_uri ~* "([^/]*$)" ) {
      set  $last_path_component  $1;
    }
    rewrite_by_lua_file /PATH/TO/NGINX/LUA/urlshortener/decode.lua;
}   
```
3. 按照注释修改配置文件 
> /PATH/TO/NGINX/LUA//urlshortener/config/const.lua  
> /PATH/TO/NGINX/LUA/urlshortener/config/redis_config.lua

4. 修改urlshortener下
* encode.lua 
* decode.lua 
* redis_utils.lua  

中package.path为nginx的lua目录 例如 /usr/local/openresty/lualib/?.lua  

5. 重启or 使配置生效 

#### 转短链
POST请求 （将TOKEN_DEFINED替换为const.lua中的密钥 YOUR_DOMAIN为你的域名)
```
curl --location --request POST 'https://YOUR_DOMAIN/shortener.star' \
--header 'Content-Type: application/json' \
--header 'bz-token: TOKEN_DEFINED' \
--data-raw '{
    "url": "https://YOUR_URL_TO_BE_SHORTEN"
}'
```
返回 
```
{"httpcode":200,"data":"https://YOUR_SHORT_URL/1"}
```
data字段的值即为短链

### 请求短链
正确打到路由之后将301跳转至原始链接





### 代码逻辑
#### redis中存储: 

1. 原地址md5结果 - 短链
 >用于对原始地址转短链时判断是否已处理， 不要重复
2. b62后的自增id - 原始地址
 >用于解短链时跳转用
3. 自增id
 >用于制作不重复的短链

#### 转短链逻辑
1. 通过redis制作一个自增sequence id 每有一个新的url插入后，就++

2. 获取每个url的md5sum， 得到一个sum

3. 去redis查询sum如果已存在直接返回对应value (原地址)

4. 如果不存在则为新地址， 从redis中获取新的sequence id，如果sequence不存在则以1为初始值， 将sequnceid 存储， 并将这个sequence id 做 b62 处理

5. b62的结果即为短链， 将其与短链域名拼接，返回给客户端

#### 解短链逻辑

1. 获取路径

2. 加上prefix中后去redis中查询

3. nginx将结果301跳转

### 其他

1. 如果需要修改转链后路径需要修改nginx.conf的location部分， 默认是 短链+字增id的b62加密结果

2. 内部报错之后没有正常的json返回（是ngixn的500页面）如有需要完善lua逻辑

3. redis使用直连模式， 如果需要sentinel支持可以扩展https://github.com/ledgetech/lua-resty-redis-connector
