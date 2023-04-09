# Pica Comic

[![flutter](https://img.shields.io/badge/flutter-3.7.10-blue)](https://flutter.dev/) 
[![License](https://img.shields.io/github/license/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/releases)
[![stars](https://img.shields.io/github/stars/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/stargazers)

非官方Picacg App, 同时支持查看E-Hentai画廊(尚未完善)

目前支持Android, Windows, Web

Web端地址 [https://comic.kokoiro.xyz/](https://comic.kokoiro.xyz/)

请尽量使用官方App

## 已实现的功能
### Picacg
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
>由于IP限制, 不提供转发服务器, 因此Web端不能访问E-Hentai. 如需使用浏览器访问,
> 请直接访问[e-hentai.org](https://www.e-hentai.org)
> 
**目前尚未完善, 可能存在各种各样的问题**
- 主页
- 热门
- 收藏夹
- 登录
- 排行榜
- 画廊详情
- 画廊阅读

## Thanks
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

## 屏幕截图

### 大屏设备
<img src="screenshots/9.png" style="width: 400px"><img src="screenshots/10.png" style="width: 400px">

### 手机
<img src="screenshots/1.png" style="width: 400px"><img src="screenshots/2.png" style="width: 400px"><img src="screenshots/3.png" style="width: 400px"><img src="screenshots/4.png" style="width: 400px"><img src="screenshots/5.png" style="width: 400px"><img src="screenshots/6.png" style="width: 400px"><img src="screenshots/7.png" style="width: 400px">

