# 自定义漫画源

## 编写js代码

使用js代码完成加载数据的操作, 以下为预定义的一些接口

### 网络请求

支持使用xhr进行网络请求, 不支持使用fetch, 为了简化网络请求, 有以下方法可供使用:

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

### 数据

#### 持久化数据

使用此函数写入的数据会被持久化

`function saveData(key, dataKey, data)`

- key: string 此漫画源的标识符
- dataKey: string 数据的标识符
- data: string

读取数据

`function loadData(key, dataKey)`

- key: string 此漫画源的标识符
- dataKey: string 数据的标识符

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