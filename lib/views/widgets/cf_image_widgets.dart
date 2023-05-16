import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

///自动检测cf设置并应用的Image.Network
class CfImageNetwork extends StatelessWidget {
  const CfImageNetwork(
    this.src,
      {
        Key? key,
        this.errorBuilder,
        this.width,
        this.height,
        this.fit
      }) : super(key: key);
  final String src;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;


  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(src);
    var realUrl = "";
    if(appdata.settings[15]=="0"||appdata.settings[3]=="1"){
      realUrl = src;
    }else if(appdata.settings[15]=="1"){
      if(network.useCf) {
        realUrl = network.apiUrl + uri.path;
      }else{
        realUrl = src;
      }
    }else{
      realUrl = "http://${appdata.settings[15]}${uri.path}";
    }
    return Image.network(
      realUrl,
      headers: {
        "Host": uri.host
      },
      errorBuilder: errorBuilder,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (BuildContext context, Widget child, int? frame, bool? wasSynchronouslyLoaded) {
        return ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant, child: child,);
      },
    );
  }
}

///自动检测cf设置并应用的CachedNetworkImage
class CfCachedNetworkImage extends StatelessWidget {
  const CfCachedNetworkImage(
      {
        Key? key,
        required this.imageUrl,
        this.errorWidget,
        this.width,
        this.height,
        this.fit,
        this.progressIndicatorBuilder,
        this.filterQuality = FilterQuality.low
      }) : super(key: key);
  final String imageUrl;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String, DownloadProgress)? progressIndicatorBuilder;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    var uri = Uri.parse(imageUrl);
    var realUrl = "";
    if(appdata.settings[15]=="0"||appdata.settings[3]=="1"){
      realUrl = imageUrl;
    }else if(appdata.settings[15]=="1"){
      if(network.useCf) {
        realUrl = network.apiUrl + uri.path;
      }else{
        realUrl = imageUrl;
      }
    }else{
      realUrl = "http://${appdata.settings[15]}${uri.path}";
    }
    return CachedNetworkImage(
      imageUrl: realUrl,
      httpHeaders: {
        "Host": uri.host
      },
      errorWidget: errorWidget,
      width: width,
      height: height,
      fit: fit,
      progressIndicatorBuilder: progressIndicatorBuilder,
      filterQuality: filterQuality,
    );
  }
}