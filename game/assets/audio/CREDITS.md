# 音效来源

`sfx/` 下全部 OGG 都由 `tools/audio/build.py` 离线合成（numpy / scipy），本项目自制，没有使用任何外部录音或采样库。
重新生成：`python3 tools/audio/build.py --all`。

枪声配方参照原型 `reference/prototype/src/n1b.js`：瞬态（crack）+ 主体噪声 + 低频冲击（thump）+ 玩具感音调 + 机械声 + 卷积混响尾音，每种至少 3 个变体。
环境音（ambience）同样是合成的：冰箱嗡嗡声（58 / 117 Hz）+ 很轻的空气噪声，8 秒循环。

`music/` 下全部 OGG（menu / match / rush / boss / victory / defeat）都由 `tools/audio/music.py` 离线合成（FM 电钢、加法合成铜管 / 钢片琴 / 马林巴 / 贝斯、噪声鼓组，乐谱写在脚本里，固定随机种子），无任何外部素材或采样。
重新生成：`python3 tools/audio/music.py --all`。

如果以后加入 CC0 素材，在这里逐条登记：文件名、原始来源链接、作者、授权。
