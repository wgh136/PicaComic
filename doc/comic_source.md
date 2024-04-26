# 自定义漫画源

## 简介

自v3.0.0版本, app允许添加自定义漫画源, 自定义漫画源通过JS语言向APP提供配置, 使用QuickJS引擎

v3.1.0版本对自定义漫画源功能进行了大幅改造

## 编写自定义漫画源

在[这里](https://github.com/wgh136/pica_configs/blob/master/template.js)下载模板

模板中有详细的注释, 没必要在这里重复说明

## API

所有的API都可以在本项目`/assets/init.js`中找到

### 网络

发起Http请求, 获取和修改Cookie

App会自动处理网络请求中的Cookie, 使用`Network`对象提供的方法可以获取和修改Cookie

对于Http请求:

所有的`data`均为任意类型

返回值为如下结构, 其中body的类型取决于调用的方法, 使用`fetchBytes`方法其类型为`ArrayBuffer`, 其他方法均为string
```
{
      "status": number,
      "headers": Object,
      "body": string | ArrayBuffer,
      "error": string?,
}
```

```js
let Network = {
    /**
     * Sends an HTTP request.
     * @param {string} method - The HTTP method (e.g., GET, POST, PUT, PATCH, DELETE).
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @param data - The data to send with the request.
     * @returns {Promise<ArrayBuffer>} The response from the request.
     */
    async fetchBytes(method, url, headers, data) {...},
    
    /**
     * Sends an HTTP request.
     * @param {string} method - The HTTP method (e.g., GET, POST, PUT, PATCH, DELETE).
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @param data - The data to send with the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async sendRequest(method, url, headers, data) {...},

    /**
     * Sends an HTTP GET request.
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async get(url, headers) {...},

    /**
     * Sends an HTTP POST request.
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @param data - The data to send with the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async post(url, headers, data) {...},

    /**
     * Sends an HTTP PUT request.
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @param data - The data to send with the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async put(url, headers, data) {...},

    /**
     * Sends an HTTP PATCH request.
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @param data - The data to send with the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async patch(url, headers, data) {...},

    /**
     * Sends an HTTP DELETE request.
     * @param {string} url - The URL to send the request to.
     * @param {Object} headers - The headers to include in the request.
     * @returns {Promise<Object>} The response from the request.
     */
    async delete(url, headers) {...},

    /**
     * Sets cookies for a specific URL.
     * @param {string} url - The URL to set the cookies for.
     * @param {Cookie[]} cookies - The cookies to set.
     */
    setCookies(url, cookies) {...},

    /**
     * Retrieves cookies for a specific URL.
     * @param {string} url - The URL to get the cookies from.
     * @returns {Promise<Cookie[]>} The cookies for the given URL.
     */
    getCookies(url) {...},

    /**
     * Deletes cookies for a specific URL.
     * @param {string} url - The URL to delete the cookies from.
     */
    deleteCookies(url) {...},
};
```

### 数据处理

此部分包含编码, 解码, 散列, 解密

```js
/// encode, decode, hash, decrypt
let Convert = {
    /**
     * @param {ArrayBuffer} value
     * @returns {string}
     */
    encodeBase64: (value) => {...},

    /**
     * @param {string} value
     * @returns {ArrayBuffer}
     */
    decodeBase64: (value) => {...},

    /**
     * @param {ArrayBuffer} value
     * @returns {ArrayBuffer}
     */
    md5: (value) => {...},

    /**
     * @param {ArrayBuffer} value
     * @returns {ArrayBuffer}
     */
    sha1: (value) => {...},

    /**
     * @param {ArrayBuffer} value
     * @returns {ArrayBuffer}
     */
    sha256: (value) => {...},

    /**
     * @param {ArrayBuffer} value
     * @returns {ArrayBuffer}
     */
    sha512: (value) => {...},

    /**
     * @param {ArrayBuffer} value
     * @param {ArrayBuffer} key
     * @returns {ArrayBuffer}
     */
    decryptAesEcb: (value, key) => {...},

    /**
     * @param {ArrayBuffer} value
     * @param {ArrayBuffer} key
     * @param {ArrayBuffer} iv
     * @returns {ArrayBuffer}
     */
    decryptAesCbc: (value, key, iv) => {...},

    /**
     * @param {ArrayBuffer} value
     * @param {ArrayBuffer} key
     * @param {number} blockSize
     * @returns {ArrayBuffer}
     */
    decryptAesCfb: (value, key, blockSize) => {...},

    /**
     * @param {ArrayBuffer} value
     * @param {ArrayBuffer} key
     * @param {number} blockSize
     * @returns {ArrayBuffer}
     */
    decryptAesOfb: (value, key, blockSize) => {...},

    /**
     * @param {ArrayBuffer} value
     * @param {ArrayBuffer} key
     * @returns {ArrayBuffer}
     */
    decryptRsa: (value, key) => {...}
}
```

### Html解析

通过与dart端交互的方式解析html

```js
/**
 * HtmlDocument class for parsing HTML and querying elements.
 */
class HtmlDocument {
    static _key = 0;

    key = 0;

    /**
     * Constructor for HtmlDocument.
     * @param {string} html - The HTML string to parse.
     */
    constructor(html) {...}

    /**
     * Query a single element from the HTML document.
     * @param {string} query - The query string.
     * @returns {HtmlDom} The first matching element.
     */
    querySelector(query) {...}

    /**
     * Query all matching elements from the HTML document.
     * @param {string} query - The query string.
     * @returns {HtmlDom[]} An array of matching elements.
     */
    querySelectorAll(query) {...}
}

/**
 * HtmlDom class for interacting with HTML elements.
 */
class HtmlDom {
    key = 0;

    /**
     * Constructor for HtmlDom.
     * @param {number} k - The key of the element.
     */
    constructor(k) {
        this.key = k;
    }

    /**
     * Get the text content of the element.
     * @returns {string} The text content.
     */
    get text() {...}

    /**
     * Get the attributes of the element.
     * @returns {Object} The attributes.
     */
    get attributes() {...}

    /**
     * Query a single element from the current element.
     * @param {string} query - The query string.
     * @returns {HtmlDom} The first matching element.
     */
    querySelector(query) {...}

    /**
     * Query all matching elements from the current element.
     * @param {string} query - The query string.
     * @returns {HtmlDom[]} An array of matching elements.
     */
    querySelectorAll(query) {...}

    /**
     * Get the children of the current element.
     * @returns {HtmlDom[]} An array of child elements.
     */
    get children() {...}
}
```

### 日志

使用下列方法发送数据给dart端, 将会显示于`设置-App-Logs`, 在debug模式下同时会输出到控制台

```js
function log(level, title, content) {...}

let console = {
    log: (content) => {
        log('info', 'JS Console', content)
    },
    warn: (content) => {
        log('warning', 'JS Console', content)
    },
    error: (content) => {
        log('error', 'JS Console', content)
    },
};
```
