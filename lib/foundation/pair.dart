class Pair<M, V>{
  M left;
  V right;

  Pair(this.left, this.right);

  Pair.fromMap(Map<M, V> map, M key): left = key, right = map[key]
      ?? (throw Exception("Pair not found"));
}