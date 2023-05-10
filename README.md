# Pica Comic

[![State-of-the-art Shitcode](https://img.shields.io/static/v1?label=State-of-the-art&message=Shitcode&color=7B5804)](https://github.com/trekhleb/state-of-the-art-shitcode)
[![flutter](https://img.shields.io/badge/flutter-3.7.12-blue)](https://flutter.dev/) 
[![License](https://img.shields.io/github/license/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/releases)
[![stars](https://img.shields.io/github/stars/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/stargazers)

非官方Picacg App, 同时支持查看E-Hentai, 禁漫天堂

目前支持Android, Windows, Web

Web端仅支持picacg且长期未更新, 因为太麻烦了

Web端地址 [https://comic.kokoiro.xyz/](https://comic.kokoiro.xyz/)

欢迎提出问题和功能建议

请尽量使用官方App

## 已实现的功能
### Picacg

没有相关推荐和本子母推荐不是App的问题, 哔咔官方告知缺乏资金, 如有能力请支持哔咔官方

- 账号
  - 登录
  - 注册
  - 个人信息, 修改头像, 修改简介
  - 签到(登录时自动进行)
- 漫画
  - 查看漫画详情
  - 喜欢/收藏
  - 阅读漫画
  - 搜索漫画
  - 收藏夹
  - 排行榜
  - 分类
  - 探索(随机漫画)
  - 评论
  - 历史记录(本地)
  - 相关推荐
  - 本子母/本子妹推荐(合并在分类里)
  - 下载漫画
- 游戏
  - 查看游戏详情
  - 评论
  - 喜欢
  - 转到游戏下载页面

### E-Hentai
- 主页
- 热门
- 收藏夹
- 登录
- 排行榜
- 画廊详情
- 画廊阅读
- 下载画廊

### 禁漫天堂
- 主页
- 最新
- 分类
- 搜索
- 漫画详情
- 漫画阅读
- 登录
- 收藏夹
- 下载漫画

## Thanks

### dependencies
- [flutter](https://flutter.dev/)
- [dio](https://pub.dev/packages/dio): 网络请求
- [get](https://pub.dev/packages/get): 路由管理
- [shared_preferences](https://pub.dev/packages/shared_preferences): 数据储存
- [dynamic_color](https://pub.dev/packages/dynamic_color): 动态颜色
- [cached_network_image](https://pub.dev/packages/cached_network_image)&[flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager): 图片缓存
- [uuid](https://pub.dev/packages/uuid): 创建uuid
- [photo_view](https://pub.dev/packages/photo_view): 图片查看
- [url_launcher](https://pub.dev/packages/url_launcher): 打开网页
- [file_selector](https://pub.dev/packages/file_selector)&[image_picker](https://pub.dev/packages/image_picker): 选择文件
- [image_gallery_saver](https://pub.dev/packages/image_gallery_saver): 将图片保存至相册
- [flutter_file_dialog](https://pub.dev/packages/flutter_file_dialog): 保存文件
- [archive](https://pub.dev/packages/archive): 压缩文件
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications): 发送通知
- [share_plus](https://pub.dev/packages/share_plus): 分享
- [local_auth](https://pub.dev/packages/local_auth): 身份认证
- [scrollable_positioned_list](https://pub.dev/packages/scrollable_positioned_list): 能够跳转到指定项目的列表(为了解决手势冲突, 我对其做出了一些修改)
- [flutter_inappwebview](https://pub.flutter-io.cn/packages/flutter_inappwebview): 用于e-hentai在webview中登录
- [dio_cookie_manager](https://pub.flutter-io.cn/packages/dio_cookie_manager): cookie管理
- [image](https://pub.flutter-io.cn/packages/image): 对禁漫图片进行切割并重新组合

### 感谢以下项目
[![Readme Card](https://github-readme-stats.vercel.app/api/pin/?username=tonquer&repo=JMComic-qt)](https://github.com/tonquer/JMComic-qt)

禁漫图片分割算法来自此项目, 并且使用chatgpt将python函数转换为了dart函数

## 屏幕截图

### 大屏设备
<img src="screenshots/9.png" style="width: 400px"><img src="screenshots/10.png" style="width: 400px">

### 手机
<img src="screenshots/1.png" style="width: 400px"><img src="screenshots/2.png" style="width: 400px"><img src="screenshots/3.png" style="width: 400px"><img src="screenshots/4.png" style="width: 400px"><img src="screenshots/5.png" style="width: 400px"><img src="screenshots/6.png" style="width: 400px"><img src="screenshots/7.png" style="width: 400px">

