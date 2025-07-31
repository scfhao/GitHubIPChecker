# GitHubIPChecker

检查当前网络可用的延时最小的 GitHub IP

## 原理

1. 通过`https://api.github.com/meta`API 获取 GitHub IP 列表；
2. 使用 HTTP 访问各 IP，找到能正确返回响应的 IP 并使用 ping 获取延时；
3. 记录延时最小的 IP，遍历完后，输出结果

## 用法

1. 下载脚本

```bash
git clone https://github.com/scfhao/GitHubIPChecker.git
```

2. 设置脚本权限

```bash
cd GitHubIPChecker
chmod +x checkGitHubIP.sh
```

3. 运行脚本

```bash
./checkGitHubIP.sh
```
