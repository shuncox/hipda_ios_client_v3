# HiPDA iOS 客户端
- [HiPDA 论坛](http://www.hi-pda.com/forum/)
- [AppStore](https://itunes.apple.com/cn/app/hipda/id728246342)
- [讨论帖](http://www.hi-pda.com/forum/viewthread.php?tid=1272557)（需登录）

# 一些技术点

### 1. 模拟Api
Discuz7.2 没有api可用, 用爬虫的方法模拟用户看帖/回帖/收藏等操作  
其中从html源文件中获取数据有下面几种方法:  
- 正则提取
- 生成 DOM 树后提取, [hpple](https://github.com/topfunky/hpple)
- 用隐藏的 UIWebView 载入页面然后用 JavaScript 提取数据 (WebKit的DOM树) [参考链接](https://github.com/gaosboy/iOSSF/blob/master/SegmentFault/DataCenters/SFQuestion.m)

经测试, 正则提取在渣CPU(iphone4)上明显较快, 但是写起来麻烦, 要细心调试  
相关代码: [HPNewPost](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPNewPost.m), [HPThread](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPThread.m), [HPSendPost](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPSendPost.m) 等(很久以前写的, 代码较渣)

### 2. UIWebView 和 Native 交互
使用 UIWebView 展示帖子详情, 并和 Native 配合做一些交互
```
为什么采用 UIWebView 而不是原生控件展示帖子?
用户发帖里面有很多html标签
如加粗, 外链, 图片, 等等, 并且复制过来的帖子标签很多不规范
很难解析也很难使用原生控件展示, 所以采用的UIWebview
```
- html模板: [post_view.html](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/View/post_view.html), 
- webview与native的交互: [HPReadViewController.m:669](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Controller/HPReadViewController.m#L669)
- webview的image与native的照片浏览器无缝动画: [HPReadViewController.m:1057](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Controller/HPReadViewController.m#L1057)


### 3. UIWebView 和 Native 共享头像/图片缓存
在帖子列表页(native)和帖子详情页(webview)都有用户头像  
列表页使用的是 SDWebImage 做加载缓存, 而 webview 内部自己处理  
这样就无法做到头像缓存的共用, 并且 webview 的缓存行为难以琢磨, 无法定制 ([参考链接](http://nshipster.com/nsurlcache/))

经过一些研究最终实现 webview 与 native 共享 image 缓存  
相关代码: [HPURLCache](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPURLCache.m), [SDImageCache+URLCache](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Helper/SDImageCache%2BURLCache.m)
```
通过自定义 NSURLCache 和改造 SDWebImage 实现共享image缓存
实现webview请求图片/头像时先从SDImageCache(memory/disk)找, 找不到再发网络请求
并且请求得到的头像图片缓存到cache中, 供以后native和webview使用
```
### 4. 自定义 NSURLProtocol 
HiPDA这个论坛的域名在移动线路上有时获取不到正确的ip  
使用自定义 NSURLProtocol, 强制将来自该域名的请求转向正确的ip地址  
相关代码: [HPURLProtocol](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPURLProtocol.m)

### 5. 利用 Background Fetch 实现伪推送
没有服务器支持怎么实时获取消息通知?   
使用 [Background Fetch](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html) 获取新消息后通过发[本地通知](https://developer.apple.com/library/ios/documentation/iPhone/Reference/UILocalNotification_Class/UILocalNotification)的方式, 实现伪推送  
Moke 等第三方微博客户端也采取这个方法做伪推送

### 6. UIWebview 的下拉刷新 & 下拉加载上一页 & 上拉翻页
在 webview.scrollview 顶部加上`下拉刷新/下拉加载上一页`和底部加上`上拉翻页`的控件  
其中在最下面加上`上拉翻页`的控件有一个问题:  
webview的contentSize是不断变化的, 所以需要相应调整控件的 origin.y  
实时调整的思路: 键值观察获得 contentSize 然后实时调整 origin.y  
```
当时还没有 SVPullToRefresh/MJRefresh 这样傻瓜化的refresh控件
只有 EGOTableViewPullRefresh 可以参考
当时得到这样的思路还是花了很多力气的
```

### 7. 使用 UIActivityViewController 分享
- 可以将帖子全文保存至`印象笔记`,`邮件`等应用
- 通过自定义 UIActivity 实现`复制链接`, `复制全文`, `保存页面完整截图`的功能

### 8. 使用七牛云服务为站内短消息加上发送图片的功能
Discuz7.2 站内短消息不能发送图片, 所以使用七牛云服务实现了此功能  
相关代码: [HPQiniuUploader](https://github.com/wujichao/hipda_ios_client_v3/blob/developer-jichao/HiPDA/Model/HPQiniuUploader.m)

# 注意
- 请不要打包后以任何形式分发
- 编译前请了解一下[CocoaPods](http://cocoapods.org/)

# 目前的不足
1. 因为没有api, 又因为刚开始编写时经验不足, 跳过了自行设计api的过程, 留下了参数不足, 不明确的隐患
2. 两年前第一次独立写完整的软件项目, 没有什么大局观, 基本是想到哪写到哪, 自(tian)豪(zhen)的采用**M**assive**V**iew**C**ontroller架构 :)