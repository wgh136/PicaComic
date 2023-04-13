import 'package:path_provider/path_provider.dart';


void debug() async{
  print((await getApplicationSupportDirectory()).path);
}