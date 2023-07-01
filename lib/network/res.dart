import 'package:flutter/cupertino.dart';

@immutable
class Res<T>{
  ///错误信息
  final String? errorMessage;

  ///数据
  final T? _data;

  ///是否出现错误
  bool get error => errorMessage!=null || _data==null;

  bool get success => !error;

  ///数据
  ///
  /// 当出现错误时调用此方法会产生错误
  T get data => _data!;

  final dynamic subData;

  @override
  String toString() => _data.toString();

  ///网络请求或者网络数据解析的返回结果
  const Res(this._data,{this.errorMessage, this.subData});
}