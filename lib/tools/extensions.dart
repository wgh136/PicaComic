extension ListExtension<T> on List<T>{
  /// Remove all blank value and return the list.
  List<T> getNoBlankList(){
    List<T> newList = [];
    for(var value in this){
      if(value.toString() != ""){
        newList.add(value);
      }
    }
    return newList;
  }

  T? firstWhereOrNull(bool Function(T element) test){
    for(var element in this){
      if(test(element)){
        return element;
      }
    }
    return null;
  }
}

extension StringExtension on String{
  ///Remove all value that would display blank on the screen.
  String get removeAllBlank => replaceAll("\n", "").replaceAll(" ", "").replaceAll("\t", "");

  /// convert this to a one-element list.
  List<String> toList() => [this];

  String _nums(){
    String res = "";
    for(int i=0; i<length; i++){
      res += this[i].isNum?this[i]:"";
    }
    return res;
  }

  String get nums => _nums();

  String setValueAt(String value, int index){
    return replaceRange(index, index+1, value);
  }

  String? subStringOrNull(int start, [int? end]){
    if(start < 0 || (end != null && end > length)){
      return null;
    }
    return substring(start, end);
  }

  String replaceLast(String from, String to) {
    if (isEmpty || from.isEmpty) {
      return this;
    }

    final lastIndex = lastIndexOf(from);
    if (lastIndex == -1) {
      return this;
    }

    final before = substring(0, lastIndex);
    final after = substring(lastIndex + from.length);
    return '$before$to$after';
  }

  static bool hasMatch(String? value, String pattern) {
    return (value == null) ? false : RegExp(pattern).hasMatch(value);
  }

  bool _isURL(){
    if(!(Uri.tryParse(this)?.hasScheme ?? false)){
      return false;
    }
    if(indexOf("https://") > 0){
      return false;
    }
    return true;
  }

  bool get isURL => _isURL();

  bool get isNum => double.tryParse(this) != null;
}

extension MapExtension<S, T> on Map<S, List<T>>{
  int _getTotalLength(){
    int res = 0;
    for(var l in values.toList()){
      res += l.length;
    }
    return res;
  }

  int get totalLength => _getTotalLength();
}