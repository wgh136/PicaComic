# scrollable_positioned_list

## About
The code in this folder is copied from [scrollable_positioned_list](https://pub.flutter-io.cn/packages/scrollable_positioned_list)

To meet my needs, I make some modifications.

## The reason I need to modify it

I want to provide a way to read comic: 
- The image is tiled vertically, like a ListView.
- Reader can use slider to jump to selected image.
- Readers can zoom in or out the entire list of images.

However, it didn't work, when I try to use ScrollablePositionedList in InteractiveView. So I try to modify it.

## what changes I make

Firstly, I use ScrollablePositionedList in [ZoomWidget](https://pub.flutter-io.cn/packages/zoom_widget). As expected,
the zoom_widget can not receive gesture signals.

Then I remove some code for detecting gestures. It works, but not good.

Finally, I pass a ScrollController to the ScrollablePositionedList. And I use AbsorbPointer to make
ScrollablePositionedList can not receive gesture signals.
Then, I use Listener to listen to gesture signals and use ScrollController to control page scrolling.

## 关于
这个文件夹里的代码是从[scrollable_positioned_list](https://pub.flutter-io.cn/packages/scrollable_positioned_list)复制过来的

为了满足我的需要，我做了一些修改。

## 我需要修改它的原因
我想提供一种阅读漫画的方法:

- 图像垂直平铺，类似于 ListView
- 读者可以使用滑块跳转到所选图像
- 读者可以放大或缩小整个图像列表
- 但是，当我尝试在 InteractiveView 中使用 ScrollablePositionedList 时,它不起作用. 所以我尝试修改它.

## 我做了什么改变
首先,我在 [ZoomWidget](https://pub.flutter-io.cn/packages/zoom_widget) 内使用 ScrollablePositionedList. 
正如预期的那样, ZoomWidget 无法接收手势信号.

然后我删除了一些用于检测手势的代码. 这样做确实起到了作用, 但效果不好.

最后,我将 ScrollController 传递给 ScrollablePositionedList. 然后用 AbsorbPointer 让 ScrollablePositionedList 收不到手势信号. 
然后，我使用 Listener 监听手势信号并用 ScrollController 控制页面滚动.