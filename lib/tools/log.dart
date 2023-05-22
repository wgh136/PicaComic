import 'package:dio/dio.dart';

void sendNetworkLog(String url, String error) async{
  try {
    var dio = Dio();
    dio.post("https://api.kokoiro.xyz/log", data: {"data": "$url $error\n"});
  }
  catch(e){
    //服务器不可用时忽视
  }
}