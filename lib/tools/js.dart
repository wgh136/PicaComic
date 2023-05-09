///解析JS代码, 返回定义的变量, Js代码必须合法
Map<String, String> getVariablesFromJsCode(String jsCode){
  final pattern = RegExp(r'var\s+(\w+)\s*=\s*(.+?);', dotAll: true);
  final matches = pattern.allMatches(jsCode);

  final variables = <String, String>{};
  for (final match in matches) {
    final key = match.group(1);
    final value = match.group(2)!.replaceAll(RegExp('[\'"]'), '');
    variables[key!] = value;
  }

  return variables;
}