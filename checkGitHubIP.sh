#!/bin/bash

# 从 https://api.github.com/meta 获取web ip列表
web_ips=$(curl -s https://api.github.com/meta | jq -r '.web[]')

server_name="github.com"

best_ip=""
best_ping_time=999

# 输出获取到的web ip列表
# echo "获取到的GitHub Web IP列表:"
# echo "$web_ips"
# 遍历IP列表
for ip in $web_ips; do
    # echo "当前处理的IP: $ip"
    # 判断IP是否为ipv6格式，如果是则跳过本次循环
    if [[ $ip == *":"* ]]; then
        continue
    fi
    # 检查是否为CIDR格式（网段）
    if [[ $ip == *"/"* ]]; then
        # 记录该网段连续失败 IP 数量
        fail_count=0
        # 使用进程替换避免子shell问题
        while read -r single_ip; do
            echo "处理网段($ip)内IP: $single_ip"
            # 这里可以添加对网段内单个IP的处理逻辑
            # 使用 curl 和 https 协议访问此 IP，忽略证书错误，并打印响应的 location 响应头
            server_header=$(curl -sI -k -H "Host: $server_name" --max-time 2 "https://$single_ip" | grep -i '^Server:' | tr -d '\r' | cut -d' ' -f2-)
            # 判断 server_header 是否不为空且第一个元素是否等于 server_name
            if [[ -n "$server_header" && "$server_header" != "null" ]]; then
                # 重置失败计数
                fail_count=0
                if [[ "$server_header" == "$server_name" ]]; then
                    # 对单个IP执行ping操作，发送4个ICMP包，获取平均延时(macOS兼容)
                    ping_result=$(ping -c 4 "$single_ip" | awk '/round-trip/ {print $4}' | cut -d '/' -f 2)
                    if [[ -z "$ping_result" ]]; then
                        # 备用提取方式
                        ping_result=$(ping -c 4 "$single_ip" | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
                    fi
                    # 判断 ping_result 是否为有效数值
                    if [[ -n "$ping_result" && "$ping_result" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                        # 将 ping_result 转换为浮点数进行比较
                        echo "$ping_result < $best_ping_time"
                        if (( $(echo "$ping_result < $best_ping_time" | bc -l) )); then
                            best_ping_time=$ping_result
                            best_ip=$single_ip
                            echo "发现更好的IP: $best_ip, 平均延时: $best_ping_time ms"
                        else
                            echo "IP $single_ip 平均延时: $ping_result ms, 高于当前最佳IP: $best_ip, 平均延时: $best_ping_time ms"
                        fi
                    else
                        echo "ping $single_ip 平均延时不是数值 $ping_result"
                    fi
                else
                    echo "IP $single_ip 返回的 server 响应头是$server_header"
                fi
            else
                echo "IP $single_ip 没有返回 server 响应头"
                # 增加失败计数
                ((fail_count++))
                # 检查失败计数是否超过阈值
                if [[ $fail_count -gt 3 ]]; then
                    echo "网段 $ip 内连续失败 IP 数量超过3个,跳过"
                    break
                fi
            fi
        done < <(nmap -sL "$ip" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    fi
done

echo "本次扫描最佳IP: $best_ip, 平均延时: $best_ping_time ms"
