///网络请求的返回结果
class Res<T>{
  ///是否出现错误
  String? error;
  ///数据
  T? data;

  @override
  String toString() => data.toString();

  Res(this.data,{this.error});
}