## 说明
使用 MineIE 运行 Qwen3-30B-A3B

需要提前准备模型权重，脚本中模型权重放在了服务器上的`/deepseek-r1/Qwen3-30B-A3B`，并把这个路径挂载到了容器中相同路径


## 配置
- MindIE 版本：2.1.RC1 及以上
- 服务器：Atlas 800I A2
- 显卡：910B4（64G），至少2张，推荐4张


## 运行

文件说明：
- `mindie-run.sh`: 启动 MindIE 容器的脚本，根据自身情况修改挂载的模型权重目录、端口映射、容器名等
- `mindie-config.json`: MindIE 配置文件，将会被挂载到容器内
- `start.sh`: MindIE 服务启动脚本（作为 MindIE 容器的 CMD 执行），将会被挂载到容器内

启动容器：
```bash
bash -x mindie-run.sh

docker logs -f qwen3-30b-a3b
```



