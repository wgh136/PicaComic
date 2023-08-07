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
}

extension StringExtension on String{
  ///Remove all value that would display blank on the screen.
  String get removeAllBlank => replaceAll("\n", "").replaceAll(" ", "").replaceAll("\t", "");

  /// convert this to a one-element list.
  List<String> toList() => [this];
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