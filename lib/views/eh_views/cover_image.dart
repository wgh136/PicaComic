import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_manager.dart';

class EhCoverImage extends StatefulWidget {
  const EhCoverImage({required this.url, this.headers = const {}, super.key});

  final String url;

  final Map<String, String> headers;

  @override
  State<EhCoverImage> createState() => _EhCoverImageState();
}

class _EhCoverImageState extends State<EhCoverImage> {
  bool error = false;

  static Map<String, Uint8List> cache = {};

  Uint8List? get data => cache[widget.url];

  set data(Uint8List? list){
    if(list != null){
      int totalSize = 0;
      cache.forEach((key, value) => totalSize += value.length);
      while(totalSize > 10 * 1024 * 1024){
        cache.remove(cache.keys.first);
      }
      cache[widget.url] = list;
    }
  }

  @override
  void didChangeDependencies() {
    if(error){
      setState(() {
        error = false;
      });
      load();
    }
    super.didChangeDependencies();
  }

  static int loading = 0;

  void load() async{
    while(loading >= 1){
      await Future.delayed(const Duration(milliseconds: 200));
    }
    loading++;
    try {
      await for(var progress in ImageManager().getImage(widget.url, widget.headers)){
        if(progress.finished){
          data = progress.getFile().readAsBytesSync();
          if(mounted){
            setState(() {});
          }
        }
      }
    }
    catch(e){
      await Future.delayed(const Duration(seconds: 5));
      if(mounted){
        setState(() {
          error = true;
        });
      }
    }
    finally{
      loading--;
    }
  }

  @override
  void initState() {
    if(data == null) {
      load();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget result;

    if(error){
      result = const Center(
        child: Icon(Icons.error),
      );
    } else if(data == null){
      result = const Center(
        child: SizedBox(width: 0, height: 0,),
      );
    } else {
      result = Image.memory(
        data!,
        fit: BoxFit.cover,
        errorBuilder: (context, url, error) => const Icon(Icons.error),
        height: double.infinity,
        width: double.infinity,
        filterQuality: FilterQuality.medium,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: result,
    );
  }
}
