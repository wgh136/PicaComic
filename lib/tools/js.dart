///解析JS代码, 返回定义的变量, Js代码必须合法
Map<String, String> getVariablesFromJsCode(String js){
  Map<String, String> res = {};
  bool status = false;
  String name = "";
  String value = "";
  for(int i = 0;i<js.length;i++){
    if(!status){
      //寻找var
      if(js[i] == 'v'){
        if(js[i+1] == 'a'&&js[i+2]=='r'){
          status = true;
          i+=2;
        }
      }
    }else{
      bool flag = false;
      //寻找变量名
      for(int j =i;j<js.length;j++,i++){
        if((js[j]==' '||js[j]=='\n')){
          if(!flag) {
            continue;
          }else{
            break;
          }
        }else{
          flag = true;
          name += js[j];
        }
      }
      while(js[i]!='='){
        i++;
      }
      i++;
      //寻找变量值
      flag = false;
      for(int j =i;j<js.length;j++,i++){
        if((js[j]==' '||js[j]=='\n'||js[j]==';')){
          if(!flag) {
            continue;
          }else{
            break;
          }
        }else{
          flag = true;
          value += js[j];
        }
      }
      //删除引号
      if(value[0]=='"'||value[0]=='\''){
        value = value.substring(1);
      }
      if(value[value.length-1]=='"'||value[value.length-1]=='\''){
        value = value.substring(0,value.length-1);
      }
      if(js[i]==';'){
        res[name] = value;
        status = false;
        name = '';
        value = '';
      }
    }
  }
  return res;
}