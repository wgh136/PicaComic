import 'package:flutter/material.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/tools/translations.dart';

const sample = '''ipb_member_id: ...
ipb_pass_hash: ...
igneous: ...
star: ...''';

class EhUserCookieParser extends StatefulWidget {
  const EhUserCookieParser({super.key, required this.controller});

  final EhUserCookieParserController controller;

  @override
  State<EhUserCookieParser> createState() => _EhUserCookieParserState();
}

class _EhUserCookieParserState extends State<EhUserCookieParser>
    with SingleTickerProviderStateMixin {
  late TextEditingController cookieDataController;
  late Map<String, String> cookieMap;

  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    cookieDataController = TextEditingController();

    scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    scaleAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: scaleController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.controller.setFunctions(show, hide, parse);
    });
  }

  @override
  void dispose() {
    cookieDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) => Center(
        child: SizedBox(
          height: 150 * scaleAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: TextField(
                maxLines: null,
                minLines: 5,
                scrollPhysics: const AlwaysScrollableScrollPhysics(),
                controller: cookieDataController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: sample.tl,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void show() {
    scaleController.forward();
  }

  void hide() {
    scaleController.reverse();
  }

  Map<String, String> parse() {
    if (cookieDataController.text.isEmpty) {
      showToast(message: "空的内容不能解析哦".tl);
      return {};
    }
    cookieMap = {};
    final rawCookieData = cookieDataController.text;
    final cookieDataPairs = rawCookieData.split('\n');
    for (var pair in cookieDataPairs) {
      final splitData = pair.split(':');
      if (splitData.length != 2) {
        showToast(message:  "cookie 信息格式可能有误".tl);
        continue;
      }
      final key = splitData[0].trim();
      final value = splitData[1].trim();
      cookieMap[key] = value;
    }
    return cookieMap;
  }
}

class EhUserCookieParserController {
  EhUserCookieParserController();

  void Function()? showFunction, hideFunction;
  Map<String, String> Function()? parseFunction;

  var visible = false;

  void setFunctions(
      Function() show, Function() hide, Map<String, String> Function() parse) {
    showFunction = show;
    hideFunction = hide;
    parseFunction = parse;
  }

  void show() {
    if (visible) return;
    visible = true;
    showFunction?.call();
  }

  void hide() {
    if (!visible) return;
    visible = false;
    hideFunction?.call();
  }

  Map<String, String> parse() {
    return parseFunction?.call() ?? {};
  }
}
