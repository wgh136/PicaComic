# 自定义漫画源

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

// TODO: 修改cookie

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
    let res = await Network.post('http://example.com/login', {
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

### 数据结构

#### 漫画信息

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

## 开始编写漫画源

### 基本信息

```toml
name = "漫画源"

key = "abcd"

version = "1.0.0"

url = "https://example.com"
```

`key`用于标识此漫画源, 用户的所有漫画源的key都不应该相同, 若有重复, 只有第一个被加载

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
            setData("logged_in", true)
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
如果成功, 使用`success`函数返回任意结果, 并且调用代码`setData("logged_in", true)`; 
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
pages = [
    "a"
]

[explore.a]
# title同时会被作为分类页面的key, 请确保其唯一性
title = "爱看漫"
type = "singlePageWithMultiPart" # "multiPageComicList"或者"singlePageWithMultiPart"
loadMultiPart = """
async function loadMultiPart(){
    try{
        let res = await Network.get("https://ymcdnyfqdapp.ikmmh.com/")
        if(res.status !== 200){
            sendError("Invalid status code: " + res.status)
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
```

### 分类页面

本app中的分类页面指的是静态的, 列出所有分类tag的页面.
对于单个漫画源, 仅可以有一个分类页面

示例:
```toml
[category]
# title同时会被作为分类页面的key, 请确保其唯一性
title = "爱看漫"
enableRankingPage = false
parts = [
    "a",
    "b"
]

[category.a]
name = "分类"
type = "fixed" # "fixed"或者"random". 如果为random, 需要设置字段`randomNumber`, 将在提供的标签中随机显示指定的数量
categories = ["全部", "长条", "大女主", "百合", "耽美", "纯爱", "後宫", "韩漫", "奇幻", "轻小说", "生活", "悬疑", "格斗", "搞笑", "伪娘", "竞技", "职场", "萌系", "冒险", "治愈", "都市", "霸总", "神鬼", "侦探", "爱情", "古风", "欢乐向", "科幻", "穿越", "性转换", "校园", "美食", "悬疑", "剧情", "热血", "节操", "励志", "异世界", "历史", "战争", "恐怖", "霸总", "全部", "连载中", "已完结", "全部", "日漫", "港台", "美漫", "国漫", "韩漫", "未分类", ]
itemType = "category" # 仅接受"category"或者"search", 或者"search_with_namespace", 用户点击时, 如果为category, 将进入定义的分类页面, 如果为search, 将进入搜索页面, 如果为search_with_namespace, 将会使用此部分的name作为namespace.
# categoryParams用于提供分类页面的参数,
# 如果提供该字段, 其长度必须与categories相等,
# 加载分类页面的函数的参数中的param将不为null
# categoryParams = []

[category.b]
name = "更新"
type = "fixed"
categories = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
itemType = "category"
```
