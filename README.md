# cf-warp
CloudFlare warp in docker  
**这个分支使用 Cloudflare 官方客户端 cf-warp**  
官方客户端目前只有 AMD64 版本  

## example
```
docker run -it \
--name wgcf_test \
--sysctl net.ipv6.conf.all.disable_ipv6=0 \
--privileged --cap-add net_admin \
-v /lib/modules:/lib/modules \
-v /tmp/wgcf/config:/var/lib/cloudflare-warp \   
1574242600/cf-warp
```

更多请参考: [Neilpang/wgcf-docker](https://github.com/Neilpang/wgcf-docker) 

