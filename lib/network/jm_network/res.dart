///网络请求的返回结果
class Res<T>{
  ///错误信息
  String? errorMessage;

  ///数据
  final T? _data;

  ///是否出现错误
  bool get error => errorMessage!=null;

  ///数据
  ///
  /// 当出现错误时调用此方法会产生错误
  T get data => _data!;

  dynamic subData;

  @override
  String toString() => _data.toString();

  Res(this._data,{this.errorMessage, this.subData});
}