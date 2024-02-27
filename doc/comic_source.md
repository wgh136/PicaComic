# 自定义漫画源

> **警告: 此功能尚未完成, 正式版与此将会有很多不同**
> 
> 欢迎提供建议

## 简介

本项目使用 toml 文件作为配置文件, 使用js代码完成数据加载的逻辑, 可以实现:
- 浏览漫画
- 搜索漫画
- 查看漫画详情
- 阅读漫画
- 下载漫画
- 登录
- 网络收藏和本地收藏
- 历史记录

## 开始编写漫画源

> 你可以在此文档的目录中找到一个示例的配置文件

### 基本信息

```toml
name = "漫画源"

key = "abcd"

version = "1.0.0"

url = "https://example.com"
```

`key`用于标识此漫画源, 用户的所有漫画源的key都不应该相同, 若有重复, 只有第一个被加载
`url`为此配置文件的url, 用于更新

### 账号

示例:
```toml
[account]

[account.login]
js = """
async function login(account, pwd){
    try {
        let res = await Network.post("https://ymcdnyfqdapp.ikmmh.com/api/user/userarr/login", {
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        }, `user=${account}&pass=${pwd}`)

        let data = JSON.parse(res.body)

        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        } else if(data["code"] !== 0){
            error("Invalid response: " + data["msg"])
        } else {
            success("Login success")
        }
    }
    catch(e) {
        error(e.toString())
    }
}
"""

[account.logout]
# 列出需要清除的数据
# 列出需要清除cookies的域名
cookies = [
    "ymcdnyfqdapp.ikmmh.com"
]
# 列出使用`setData`方法储存的数据的key
data = []

[account.register]
website = "https://ymcdnyfqdapp.ikmmh.com/user/register/"
```

#### 登录
需要实现函数`async function login(account, pwd)`. 
如果成功, 使用`success`函数返回任意结果; 
如果失败, 使用`error`函数返回错误.

#### 注销
需要完成`cookies`和`data`字段, 用于清除登录信息

#### 注册
需要提供注册页面的url

### 探索页面
一个漫画源可以拥有多个探索页面

示例:
```toml
[explore]

[[explore.pages]]
# title同时会被作为分类页面的key, 请确保其唯一性
title = "爱看漫"
type = "singlePageWithMultiPart" # "multiPageComicList"或者"singlePageWithMultiPart"
loadMultiPart = """
async function loadMultiPart(){
    try{
        let res = await Network.get("https://ymcdnyfqdapp.ikmmh.com/")
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let document = new HtmlDocument(res.body)
        function parseComicDom(comicDom){
            let title = comicDom.querySelector("h4").text
            let cover = comicDom.querySelector("img").attributes["data-src"]
            let tags = []
            let tagDoms = comicDom.querySelectorAll("div.tag-wrap > p")
            for(let j = 0; j < tagDoms.length; j++){
                tags.push(tagDoms[j].text.trim())
            }
            tagDoms = comicDom.querySelectorAll("div.anime-mask > p")
            for(let j = 0; j < tagDoms.length; j++){
                tags.push(tagDoms[j].text.trim())
            }
            let link = comicDom.querySelector("a").attributes["href"]
            link = "https://ymcdnyfqdapp.ikmmh.com" + link
            return {
                title: title,
                cover: cover,
                tags: tags,
                id: link
            };
        }

        let data = {
            "海量精品漫画": document.querySelectorAll("ul.panel-comic-r > li").map(parseComicDom),
            "热门人气新番": document.querySelectorAll("ul.list-anime > li").map(parseComicDom),
        }

        success(data)
    }
    catch (e){
        error(e.toString())
    }
}
"""

# 如果类型为multiPageComicList, 需要提供loadPage函数
# loadPage = """
# async function loadPage(page){
#   // 此函数返回结果见文档中的数据结构部分
# }
# """
```

探索页面有两种类型:
- `multiPageComicList`: 多页漫画列表
- `singlePageWithMultiPart`: 单页多部分漫画列表

#### 加载多部分
需要实现函数`async function loadMultiPart()`.
如果成功, 使用`success`函数返回结果, 结果应该是一个map, 其中key为该部分的名称, value为漫画简略信息的数组

#### 加载多页面漫画列表
如果类型为`multiPageComicList`, 需要提供`loadPage`函数
需要实现函数`async function loadPage(page)`.
返回结果见此文档的数据结构部分

### 分类页面

本app中的分类页面指的是静态的, 列出所有分类tag的页面.
对于单个漫画源, 仅可以有一个分类页面

> 注意: 排行榜尚未实现

示例:
```toml
[category]
# title同时会被作为分类页面的key, 请确保其唯一性
title = "爱看漫"
enableRankingPage = false

[[category.parts]]
name = "分类"
type = "fixed" # "fixed"或者"random". 如果为random, 需要设置字段`randomNumber`, 将在提供的标签中随机显示指定的数量
categories = ["全部", "长条", "大女主", "百合", "耽美", "纯爱", "後宫", "韩漫", "奇幻", "轻小说", "生活", "悬疑", "格斗", "搞笑", "伪娘", "竞技", "职场", "萌系", "冒险", "治愈", "都市", "霸总", "神鬼", "侦探", "爱情", "古风", "欢乐向", "科幻", "穿越", "性转换", "校园", "美食", "悬疑", "剧情", "热血", "节操", "励志", "异世界", "历史", "战争", "恐怖", "霸总", "全部", "连载中", "已完结", "全部", "日漫", "港台", "美漫", "国漫", "韩漫", "未分类", ]
itemType = "category" # 仅接受"category"或者"search", 或者"search_with_namespace", 用户点击时, 如果为category, 将进入定义的分类页面, 如果为search, 将进入搜索页面, 如果为search_with_namespace, 将会使用此部分的name作为namespace.

[[category.parts]]
name = "更新"
type = "fixed"
categories = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
itemType = "category"
# categoryParams用于提供分类页面的参数,
# 如果提供该字段, 其长度必须与categories相等,
# 加载分类页面的函数的参数中的param将不为null
categoryParams = ['1', '2', '3', '4', '5', '6', '7']
```

### 分类漫画页面

分类漫画页面指的是根据分类tag列出漫画的页面, 可以拥有一些选项, 例如排序, 筛选等

示例:
```toml
[categoryComics]
load = """
async function load(category, param, options, page){
    try{
        category = encodeURIComponent(category)
        let url = ""
        if(param !== undefined && param !== null){
            url = `https://ymcdnyfqdapp.ikmmh.com/update/${param}.html`
        } else {
            url = `https://ymcdnyfqdapp.ikmmh.com/booklists/${options[1]}/${category}/${options[0]}/${page}.html`
        }
        let res = await Network.get(url)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let document = new HtmlDocument(res.body)

        function parseComic(element){
            let title = element.querySelector("h2").text
            let cover = element.querySelector("img").attributes["data-src"]
            let tags = []
            let tagDoms = element.querySelectorAll("div.tag-list > p")
            for(let j = 0; j < tagDoms.length; j++){
                tags.push(tagDoms[j].text.trim())
            }
            let link = element.querySelector("a").attributes["href"]
            link = "https://ymcdnyfqdapp.ikmmh.com" + link
            let updateInfo = element.querySelector("p.process").text
            return {
                title: title,
                cover: cover,
                tags: tags,
                id: link,
                subTitle: updateInfo
            };
        }

        let maxPage = 1
        if(param === undefined || param === null){
            maxPage = document.querySelectorAll("ul.list-page > li > a").pop().text
            maxPage = parseInt(maxPage)
        }
        success({
            comics: document.querySelectorAll("ul.list-comic-book > li").map(parseComic),
            maxPage: maxPage
        })
    }
    catch (e){
        error(e.toString())
    }
}
"""

[[categoryComics.options]]
# content 用于提供分类页面的选项, 按照如下格式, 使用`-`分割, 左侧为加载使用的参数, 右侧为显示在屏幕上的选项文字
content = """
3-全部
4-连载中
1-已完结
"""
# notShowWhen提供一个列表, 当分类页面的名称为列表中的任意一个时, 将不会显示此选项
notShowWhen = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]

[[categoryComics.options]]
content = """
9-全部
1-日漫
2-港台
3-美漫
4-国漫
5-韩漫
6-未分类
"""
notShowWhen = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
```

#### 提供选项
提供一个数组, 其中每一个元素, 都包含`content`和`notShowWhen`字段

`content`用于提供分类页面的选项, `notShowWhen`提供一个列表, 当分类页面的名称为列表中的任意一个时, 将不会显示此选项

#### 加载漫画
需要实现函数`async function load(category, param, options, page)`.

`category`为分类页面的名称, `param`为分类页面的参数, `options`为提供的选项值列表, `page`为当前页面序号.

如果成功, 使用`success`函数返回结果, 结果应该包含`comics`和`maxPage`字段, `comics`为漫画列表, `maxPage`为最大页数.

### 搜索

与分类漫画页面类似

示例:
```toml
[search]
load = """
async function load(keyword, options, page){
    try{
        let res = await Network.get(`https://ymcdnyfqdapp.ikmmh.com/search?searchkey=${encodeURIComponent(keyword)}`)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let document = new HtmlDocument(res.body)

        function parseComic(element){
            let title = element.querySelector("a").text
            let cover = element.querySelector("img").attributes["data-src"]
            let link = element.querySelector("a").attributes["href"]
            link = "https://ymcdnyfqdapp.ikmmh.com" + link
            let updateInfo = element.querySelector("p.describe > a").text
            return {
                title: title,
                cover: cover,
                id: link,
                subTitle: updateInfo
            };
        }

        success({
            comics: document.querySelectorAll("div.classification").map(parseComic),
            maxPage: 1
        })
    }
    catch (e){
        error(e.toString())
    }
}
"""

[[search.options]]
label = "排序模式"
content = """
1-最新
2-最热
3-评分
"""
```

### 网络收藏

提供添加和删除收藏功能, 加载收藏列表功能

> 注意: 多收藏夹式的收藏功能尚未实现

示例:
```toml
[favorite]
# 是否是多收藏夹
multiFolder = false 
# 添加或者删除收藏, 如果是添加收藏, isAdding为true
addOrDelFavorite = """
async function addOrDelFavorite(comicId, folderId, isAdding){
    let id = comicId.split("/")[4]
    if(isAdding){
        let comicInfoRes = await Network.get(comicId);
        if(comicInfoRes.status !== 200){
            error("Invalid status code: " + res.status)
            return;
        }
        let document = new HtmlDocument(comicInfoRes.body)
        let name = document.querySelector("h1").text;
        let res = await Network.post("https://ymcdnyfqdapp.ikmmh.com/api/user/bookcase/add", {
            "Content-Type": "application/x-www-form-urlencoded",
        }, `articleid=${id}&articlename=${name}`)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
            return;
        }
        let json = JSON.parse(res.body)
        if(json["code"] === "0"){
            success("ok")
        } else if(json["code"] === 1) {
            error("Login expired")
        } else {
            error(json["msg"].toString())
        }
    } else {
        let res = await Network.post("https://ymcdnyfqdapp.ikmmh.com/api/user/bookcase/del", {
            "Content-Type": "application/x-www-form-urlencoded",
        }, `articleid=${id}`)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
            return;
        }
        let json = JSON.parse(res.body)
        if(json["code"] === "0"){
            success("ok")
        } else if(json["code"] === 1) {
            error("Login expired")
        } else {
            error(json["msg"].toString())
        }
    }
}

"""
loadComics = """
async function loadComics(page, folder){
    try{
        let res = await Network.post("https://ymcdnyfqdapp.ikmmh.com/api/user/bookcase/ajax", {
            "Content-Type": "application/x-www-form-urlencoded",
        }, `page=${page}`)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let json = JSON.parse(res.body)
        if(json["code"] === "1"){
            error("Login expired")
            return;
        }
        if(json["code"] !== "0"){
            error("Invalid response: " + json["code"])
            return;
        }
        let comics = json["data"].map(e => {
            return {
                title: e["name"],
                subTitle: e["author"],
                cover: e["cover"],
                id: "https://ymcdnyfqdapp.ikmmh.com" + e["info_url"]
            }
        })
        let maxPage = json["end"]
        success({
            comics: comics,
            maxPage: maxPage
        })
    }
    catch (e){
        error(e.toString())
    }
}
"""
```

对于收藏功能, 如果返回结果为`error("Login expired")`, 将会自动重新登录, 并且重试

#### 添加或删除收藏
需要实现函数`async function addOrDelFavorite(comicId, folderId, isAdding)`
- comicId: 漫画的id
- folderId: 收藏夹的id, 如果是多收藏夹, 需要使用此字段, 否则可以忽略
- isAdding: 是否是添加收藏
- 如果成功, 使用`success`函数返回任意结果;

#### 加载收藏列表
需要实现函数`async function loadComics(page, folder)`
- page: 当前页数
- folder: 当前收藏夹的id, 如果是多收藏夹, 需要使用此字段, 否则可以忽略
- 返回结果应该包含`comics`和`maxPage`字段, `comics`为漫画列表, `maxPage`为最大页数.

### 加载漫画信息

此部分用于加载漫画的详细信息和章节图片

示例:
```toml
[comic]

loadInfo = """
async function loadInfo(id){
    try{
        let res = await Network.get(id)
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let document = new HtmlDocument(res.body)
        let title = document.querySelector("h1.detail-title").text
        let cover = document.querySelector("div.banner-img > img").attributes["data-src"]
        let author = document.querySelector("p.author").text
        let tags = document.querySelectorAll("p.ui-tag > a").map(e => e.text.trim())
        let description = document.querySelector("div.detail-desc").text
        let updateTime = document.querySelector("div.detail-info > div > span > b").text
        let eps = {}
        document.querySelectorAll("ol.chapter-list > li").forEach(element => {
            let title = element.querySelector("a").attributes["title"]
            let id = element.attributes["data-chapter"]
            eps[id] = title
        })
        let comics = document.querySelectorAll("div.mod-vitem-comic").map(element => {
            let title = element.querySelector("h4").text
            let cover = element.querySelector("img").attributes["data-src"]
            let link = element.querySelector("a").attributes["href"]
            link = "https://ymcdnyfqdapp.ikmmh.com" + link
            return {
                title: title,
                cover: cover,
                id: link
            }
        })
        success({
            title: title,
            cover: cover,
            description: description,
            tags: {
                "作者": [author],
                "更新": [updateTime],
                "标签": tags
            },
            chapters: eps,
            suggestions: comics
        })
    }
    catch (e){
        error(e.toString())
    }
}
"""

loadEp = """
async function loadEp(comicId, epId){
    try{
        if(comicId.includes("https://")){
            comicId = comicId.split("/")[4]
        }
        let res = await Network.get(
            `https://ymcdnyfqdapp.ikmmh.com/chapter/${comicId}/${epId}.html`,
            {
                "Referer": `https://ymcdnyfqdapp.ikmmh.com/book/${comicId}.html`,
                "User-Agent": "Mozilla/5.0 (Linux; Android 10; SM-G9600) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36"
            }
        )
        if(res.status !== 200){
            error("Invalid status code: " + res.status)
        }
        let document = new HtmlDocument(res.body)
        success({
            images: document.querySelectorAll("img.lazy").map(e => e.attributes["data-src"])
        })
    }
    catch (e){
        error(e.toString())
    }
}
"""
```

#### 加载漫画详情
需要实现函数`async function loadInfo(id)`
- id: 通过漫画简略信息得到的id
- 返回结果详见此文档的数据结构部分

#### 加载章节图片
需要实现函数`async function loadEp(comicId, epId)`
- comicId: 通过漫画简略信息得到的id
- epId: 章节id, 如果是多章节, 需要使用此字段, 否则可以忽略

### 设置

漫画源配置文件可以向app的设置页面提供一些设置项

> TODO: 设置项尚未实现

## js代码

使用js代码完成加载数据的操作, 以下为预定义的一些接口

### 网络请求

#### 发送网络请求
xhr和fetch均不可使用, 以下代码通过与dart交互实现网络请求:

网络请求始终返回string类型的数据, 请自行解析json或者html

```js
class Network {
    static async sendRequest(method, url, headers, data) {
        // 实现省略
    }

    static async get(url, headers) {
        return this.sendRequest('GET', url, headers);
    }

    static async post(url, headers, data) {
        return this.sendRequest('POST', url, headers, data);
    }

    static async put(url, headers, data) {
        return this.sendRequest('PUT', url, headers, data);
    }

    static async patch(url, headers, data) {
        return this.sendRequest('PATCH', url, headers, data);
    }
}
```


#### cookie
cookie将被自动持久化储存

由于dart的cookie校验严格, 不符合规范的cookie会被放到响应头的`invalid-cookie`中, 且此部分cookie不会被持久化储存

很多老旧的网站会使用不符合规范的cookie, 请注意

### 数据

#### 持久化数据

使用json格式持久化数据

使用此函数写入数据

`function setData(key, data)`

- key: string 此数据的标识符
- data: any

读取数据

`function loadData(key)`

- key: string 数据的标识符
- return: any

#### 临时数据

在js运行时启动时, 定义了此变量

`let tempData = {}`

向该变量写入数据即可

### 日志

使用此函数记录日志

`function log(level, title, content)`

- level: string 仅接受 'error', 'warning', 'info'
- title: string
- content: string

### 返回结果

在所有需要编写js代码的地方, 都需要编写一个函数, 例如登录:
```js
async function login(username, password) {
    let res = await Network.post('https://example.com/login', {
        'Content-Type': 'application/json'
    }, JSON.stringify({
        username: username,
        password: password
    }));
    
    if(res.status !== 200) {
        sendError("登录失败")
    } else {
        success("ok")
    }
}
```

使用`success`函数返回结果, 使用`sendError`函数返回错误

### 解析html

由于处于非浏览器环境, 无法使用`DOMParser`

为了实现解析html, 并且减少第三方库的依赖, 采用了与Dart端交互的方式实现解析html

#### api

加载html

`let document = new HtmlDocument(html)`

获取元素

`let element = document.querySelector(selector)`

`let elements = document.querySelectorAll(selector)`

使用元素

`let attributes = element.attributes`

`let text = element.text`

`let children = element.children`

`let element1 = element.querySelector(selector)`

`let elements1 = element.querySelectorAll(selector)`

### 加密解密

#### base64
```js
let data = "<data>"
let encodedData = Convert.encodeBase64(data)
let decodedData = Convert.decodeBase64(data)
```

#### md5
```js
let data = "<data>"
let encodedData = Convert.md5(data)
```

### 数据结构

#### 漫画信息

此数据结构用于加载漫画列表中的漫画的简略信息

```
{
    title: string,
    subtitle: string?,
    cover: string,
    id: string,
    tags: string[],
    description: string?,
}
```

- id: 用于加载漫画的详细信息, 可以是漫画的url, 也可以是漫画的id
- description: 漫画的某种信息, 取决于漫画源的提供的数据, 可以是上传时间, 语言, 等等

#### 漫画详细信息

此数据结构用于显示漫画的详细信息

```
{
    title: string,
    subtitle: string?,
    cover: string,
    description: string?,
    tags: map<string, string[]>,
    chapters: map<string, string>?,
    thumbnails: string[]?,
    thumbnailLoader: string?,
    thumbnailMaxPage: number?,
    suggestions: {
        title: string,
        subtitle: string?,
        cover: string,
        id: string,
        tags: string[],
        description: string?,
    }[],
}
```

- chapters: 漫画的章节, key为章节id, value为章节标题
- thumbnails: 漫画的缩略图, 用于显示章节列表的缩略图
- thumbnailLoader: (尚未实现)加载缩略图的函数
- thumbnailMaxPage: (尚未实现)缩略图的最大页数
- suggestions: 推荐的漫画, 用于显示在漫画详情页的推荐列表

#### 漫画列表

此数据结构为加载漫画列表的某一页返回的数据

```
{
    comics: {
        title: string,
        subtitle: string?,
        cover: string,
        id: string,
        tags: string[],
        description: string?,
    }[],
    maxPage: number,
}
```