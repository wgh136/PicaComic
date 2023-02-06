import 'dart:collection';
import 'dart:ffi';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/models.dart';

var network = Network();

var comics = <ComicItemBrief>[];



class Appdata{
  late String token;
  late Profile user;
  late List<ComicItemBrief> history;
  Appdata(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "");
    user = temp;
    history = [];
  }
  Future<void> writeData() async{
    var s = await SharedPreferences.getInstance();
    await s.setString("token", token);
    await s.setString("userName", user.name);
    await s.setString("userAvatar", user.avatarUrl);
    await s.setString("userId", user.id);
    await s.setString("userEmail", user.email);
    await s.setInt("userLevel",user.level);
    await s.setInt("userExp",user.exp);
    await s.setString("userTitle", user.title);
    await s.setInt("historyLength",history.length);
    for(int i=0;i<history.length;i++){
      var data = [history[i].title,history[i].id,history[i].author,history[i].path,history[i].likes.toString()];
      await s.setStringList("historyData$i", data);
    }
  }
  Future<bool> readData() async{
    var s = await SharedPreferences.getInstance();
    try{
      token = (s.getString("token"))!;
      user.name = s.getString("userName")!;
      user.title = s.getString("userTitle")!;
      user.level = s.getInt("userLevel")!;
      user.email = s.getString("userEmail")!;
      user.avatarUrl = s.getString("userAvatar")!;
      user.id = s.getString("userId")!;
      user.exp = s.getInt("userExp")!;
      for(int i=0;i<s.getInt("historyLength")!;i++){
        var data = s.getStringList("historyData$i");
        var c = ComicItemBrief(data![0], data[2], int.parse(data[4]), data[3], data[1]);
        history.add(c);
      }
      return token==""?false:true;
      return true;
    }
    catch(e){
      return false;
    }
  }
}

var appdata = Appdata();