import 'package:pica_comic/network/methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/models.dart';

var network = Network();

const changePoint = 600; //定义宽屏设备的临界值
const appVersion = "1.1.8";

class Appdata{
  late String token;
  late Profile user;
  late List<ComicItemBrief> history;
  late String appChannel;
  List<String> settings = [
    "1", //点击屏幕左右区域翻页
    "dd", //排序方式
    "1", //启动时检查更新
    "0", //使用转发服务器
  ];
  Appdata(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null);
    user = temp;
    history = [];
    appChannel = "3";

  }

  int getSearchMod(){
    var modes = ["dd","da","ld","vd"];
    return modes.indexOf(settings[1]);
  }

  void saveSearchMode(int mode) async{
    var modes = ["dd","da","ld","vd"];
    settings[1] = modes[mode];
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
  }

  void clear(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null);
    user = temp;
    history = [];
    writeData();
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
    await s.setString("appChannel",appChannel);
    await s.setStringList("settings", settings);
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
      if(s.getStringList("settings")!=null) {
        var st = s.getStringList("settings")!;
        for(int i=0;i<st.length;i++){
          settings[i] = st[i];
        }
      }
      for(int i=0;i<s.getInt("historyLength")!;i++){
        var data = s.getStringList("historyData$i");
        var c = ComicItemBrief(data![0], data[2], int.parse(data[4]), data[3], data[1]);
        history.add(c);
      }
      appChannel = s.getString("appChannel")!;
      return token==""?false:true;
    }
    catch(e){
      return false;
    }
  }
}

var appdata = Appdata();