import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../foundation/app.dart';
import '../views/eh_views/eh_gallery_page.dart';
import '../views/hitomi_views/hitomi_comic_page.dart';
import '../views/main_page.dart';
import '../views/nhentai/comic_page.dart';
import '../views/widgets/show_message.dart';

bool canHandle(String text){
  if(!text.isURL){
    return false;
  }
  var uri = Uri.parse(text);

  const acceptedHosts = ["e-hentai.org", "exhentai.org", "nhentai.net", "hitomi.la"];

  return acceptedHosts.contains(uri.host);
}

bool handleAppLinks(Uri uri, {bool showMessageWhenError = true}){
  LogManager.addLog(LogLevel.info, "App Link", "Open Link $uri");
  switch(uri.host){
    case "e-hentai.org":
    case "exhentai.org":
      if(uri.path.contains("/g/")){
        MainPage.to(() => EhGalleryPage.fromLink("https://${uri.host}${uri.path}"));
      }
    case "nhentai.net":
      if(uri.path.contains("/g/")){
        MainPage.to(() => NhentaiComicPage(uri.pathSegments.firstWhere((element) => element.isNum)));
      }
    case "hitomi.la":
      if(["doujinshi", "cg", "manga"].contains(uri.pathSegments[0])){
        MainPage.to(() => HitomiComicPage.fromLink("https://${uri.host}${uri.path}"));
      }else{
        showMessage(App.globalContext, "Unknown Link");
        return false;
      }
    default:
      return false;
  }
  return true;
}