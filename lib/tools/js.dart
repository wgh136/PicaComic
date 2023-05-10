///解析JS代码, 返回定义的变量, Js代码必须合法
Map<String, String> getVariablesFromJsCode(String html){
  Map<String, String> variables = {};

  RegExp variableRegex = RegExp(r"var\s+(\w+)\s*=\s*(.*?);");
  var matches = variableRegex.allMatches(html);

  for (Match match in matches) {
    if(match.group(2)![0]=="\"" || match.group(2)![0]=="'"){
      variables[match.group(1)!] = match.group(2)!.substring(1,match.group(2)!.length-1);
    }else {
      variables[match.group(1)!] = match.group(2)!;
    }
  }
  return variables;
}