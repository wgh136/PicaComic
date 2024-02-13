# 自定义漫画源

## 编写js代码

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


