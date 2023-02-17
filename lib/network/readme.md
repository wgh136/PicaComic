# Picacg Network Api

## 简述
使用Network类实现多数网络请求

除登录外, 其他接口均需登录

## 类方法

`Future<bool> login(String email, String password) async`

登录接口

`Future<Profile?> getProfile() async`

获取用户信息

`Future<KeyWords?> getKeyWords() async`

获取热搜词

`Future<bool> init() async`

获取基本信息:imageServer,fileServer,分类

`Future<SearchResult> searchNew(String keyWord,String sort) async`

搜索, 返回SearchResult对象

sort参数指定排序方式:
dd: 新到书
da: 旧到新
ld: 最多喜欢
vd: 最多绅士指名

`Future<void> loadMoreSearch(SearchResult s) async`

获取下一页搜索结果

`Future<ComicItem?> getComicInfo(String id) async`

使用漫画id获取漫画详细信息

`Future<List<String>> getEps(String id) async`

使用漫画id获取漫画章节信息, 返回字符串列表, 0号为为空字符串, 其后为各个章节, 下标对应章节的order

`Future<List<String>> getComicContent(String id, int order) async`

使用漫画id和order获取漫画内容, 返回图片地址列表

`Future<Commends> getCommends(String id) async`

使用漫画id, 返回Commends对象, 该对象中已经加载了第一页的评论

`Future<void> loadMoreCommends(Commends c) async`

使用一个Commends对象, 加载下一页的内容

`Future<Favorites> getFavorites() async`

获取收藏夹, 返回Favorites对象, 该对象中已经加载了第一页的内容

`Future<void> loadMoreFavorites(Favorites f) async`

使用一个Favorites对象, 加载下一页内容

`Future<List<ComicItemBrief>> getRandomComics() async`

获取随机本子

`Future<bool> likeOrUnlikeComic(String id) async`

喜欢或不喜欢漫画

`Future<bool> favouriteOrUnfavoriteComic(String id) async`

收藏或不收藏漫画

`Future<List<ComicItemBrief>> getLeaderboard(String time) async`

获取排行榜

Time:
H24 过去24小时,
D7 过去7天,
D30 过去30天

`Future<bool> punchIn()async`

打卡

`Future<bool> uploadAvatar(String imageData) async`

上传头像, 数据仍然是json, 只有一条"avatar"数据, 数据内容为base64编码的图像, 例如{"avatar":"[在这里放图像数据]"}

`Future<bool> changeSlogan(String slogan) async`

改变简介

`Future<Reply> getReply(String id) async) async`

获取回复

`Future<bool> likeOrUnlikeComment(String id) async`

评论点赞

`Future<bool> comment(String id, String text,bool isReply,{String type="comics"}) async`

发送评论

`Future<List<ComicItemBrief>> getRecommendation(String id) async`

获取相关推荐, 需要两级

`Future<List<List<ComicItemBrief>>?> getCollection() async`

获取本子母/本子妹推荐

`Future<Games?> getGames() async`

获取游戏

`Future<bool> likeGame(String id) async`

喜欢游戏