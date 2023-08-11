# Pica Comic

[![flutter](https://img.shields.io/badge/flutter-3.10.6-blue)](https://flutter.dev/) 
[![License](https://img.shields.io/github/license/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/blob/master/LICENSE)
[![Download](https://img.shields.io/github/v/release/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/releases)
[![stars](https://img.shields.io/github/stars/wgh136/PicaComic)](https://github.com/wgh136/PicaComic/stargazers)

使用flutter构建的漫画App, 支持查看Picacg, E-hentai, 禁漫天堂, Hitomi, 绅士漫画

目前支持Android, Windows, IOS, linux(实验性); 

本App目标为中文漫画, 因此App界面语言仅支持中文, 漫画源仅限于有中文漫画的漫画源

Web端已被放弃, 仅支持哔咔, 目前部署在Vercel上
地址: [https://comic.kokoiro.xyz/](https://comic.kokoiro.xyz/)

欢迎提出问题和功能建议

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

### Hitomi
- 主页
- 排行榜(popular)
- 搜索
- 漫画详情
- 漫画阅读
- 下载漫画

### 绅士漫画
在v2.0.0版本中添加
- 主页
- 分类
- 搜索
- 漫画详情
- 漫画阅读
- 登录
- 收藏夹
- 下载漫画

## 从源代码构建
首先, 必须安装**Stable频道最新版**[Flutter SDK](https://docs.flutter.dev/get-started/install)

然后将本项目克隆至本地

### 构建APK
1. 安装Android Studio
2. 创建签名证书: 可以通过Java的keytool创建, 或者使用Android Studio进行创建
3. 在/PicaComic/android/下创建文件`key.properties`, 内容如下, 等号右边更改为创建签名时提供的数据, `storeFile`填写签名证书的位置
```
storePassword=
keyPassword=
keyAlias=
storeFile=
```
4. 在终端运行`flutter pub get`
5. 在终端运行`flutter build apk`

### 构建Windows
1. 安装Visual Studio, 并且勾选使用C++的桌面开发
2. 打开/PicaComic/pubspec.yaml, 移至文件末尾, 找到注释`仅在打包windows时取消注释`, 将下面的字体使用取消注释. 你也可以将字体替换为其他字体
3. 在终端运行`flutter pub get`
4. 在终端运行`flutter build windows`

### 构建IOS
可以直接在[Action](https://github.com/wgh136/PicaComic/actions)页面查看构建结果

### 其他平台?
其它平台暂时不受支持, 你可以尝试构建, 并且遇到问题时可以提出issue, 但并不会在第一时间得到处理

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

本项目仍在持续开发中, 以下屏幕截图可能并非来自最新版本

### 大屏设备
<img src="screenshots/9.png" style="width: 400px"><img src="screenshots/10.png" style="width: 400px">

### 手机
<img src="screenshots/1.png" style="width: 400px"><img src="screenshots/2.png" style="width: 400px"><img src="screenshots/3.png" style="width: 400px"><img src="screenshots/4.png" style="width: 400px"><img src="screenshots/5.png" style="width: 400px"><img src="screenshots/6.png" style="width: 400px"><img src="screenshots/7.png" style="width: 400px">

