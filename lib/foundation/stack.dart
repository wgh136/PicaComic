import 'dart:collection';

class Stack<T>{
  final Queue<T> _values;

  Stack():_values = Queue();

  int get length => _values.length;
  bool get isEmpty => _values.isEmpty;
  bool get isNotEmpty => _values.isNotEmpty;

  void push(T value){
    _values.addLast(value);
  }

  T pop(){
    return _values.removeLast();
  }

  T get last => _values.last;
}