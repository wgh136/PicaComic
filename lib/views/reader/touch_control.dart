import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import '../../base.dart';

/// Control scroll when readingMethod is [ReadingMethod.topToBottomContinuously]
/// and the image has been enlarge
class ScrollManager {
  ComicReadingPageLogic logic;

  ScrollManager(this.logic);

  Offset? tapLocation;

  int? startTime;

  Offset? moveOffset;

  int get fingers => TapController.fingers;

  void tapDown(PointerDownEvent details) {
    moveOffset = Offset.zero;
    startTime = DateTime.now().millisecondsSinceEpoch;
    var logic = StateController.find<ComicReadingPageLogic>();
    var temp = logic.noScroll;
    logic.noScroll = fingers >= 2;
    if (temp != logic.noScroll) {
      logic.update();
    }
  }

  void tapUp(PointerUpEvent details) {
    var logic = StateController.find<ComicReadingPageLogic>();
    var temp = logic.noScroll;
    logic.noScroll = fingers >= 2;
    if (temp != logic.noScroll) {
      logic.update();
    }
    tapLocation = null;

    if (moveOffset != null && moveOffset != Offset.zero) {
      if (moveOffset!.dx * moveOffset!.dx + moveOffset!.dy * moveOffset!.dy >
          400) {
        final offset = moveOffset! /
            (DateTime.now().millisecondsSinceEpoch - startTime!).toDouble() *
            100;
        logic.photoViewController.animatePosition?.call(
            logic.photoViewController.position,
            logic.photoViewController.position + offset);
      }
    }
    moveOffset = null;
    startTime = null;
    if (logic.fABValue < 58) {
      logic.fABValue = 0;
      logic.update(["FAB"]);
    } else if (logic.fABValue >= 58) {
      logic.fABValue = 0;
      logic.jumpToNextChapter();
    }
  }

  /// handle pointer move event
  void addOffset(Offset value) {
    if (logic.scrollController.offset ==
            logic.scrollController.position.maxScrollExtent &&
        logic.photoViewController.scale == 1 &&
        logic.showFloatingButtonValue == 1) {
      logic.fABValue -= value.dy / 3;
      logic.update(["FAB"]);
      return;
    }
    if (logic.photoViewController.scale == 1) {
      return;
    }
    if (moveOffset != null) {
      moveOffset = moveOffset! + value;
    }
    if (logic.scrollController.offset !=
            logic.scrollController.position.maxScrollExtent &&
        logic.scrollController.offset !=
            logic.scrollController.position.minScrollExtent) {
      value = Offset(value.dx, 0);
    }
    logic.photoViewController
        .updateMultiple(position: logic.photoViewController.position + value);
    return;
  }
}

class _TapDownPointer{
  int id;
  Offset offset;

  double getDistance(){
    return offset.dx * offset.dx + offset.dy * offset.dy;
  }

  _TapDownPointer(this.id): offset = const Offset(0, 0);
}

class TapController {
  static Offset? _tapOffset;

  static DateTime lastScrollTime = DateTime(2023);

  static bool ignoreNextTap = false;

  static bool longTimePressScale = false;

  static _TapDownPointer? _tapDownPointer;

  static void Function(PointerUpEvent event)? onTapUpReplacement;

  static int fingers = 0;

  static void onTapCancel(PointerCancelEvent event){
    fingers--;
  }

  static void onTapDown(PointerDownEvent event) {
    fingers++;
    if(ignoreNextTap){
      ignoreNextTap = false;
      return;
    }
    var logic = StateController.find<ComicReadingPageLogic>();

    if(appdata.settings[55] == "1") {
      _tapDownPointer = _TapDownPointer(event.pointer);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (event.pointer == _tapDownPointer?.id) {
          onTapUpReplacement = _handleLongPressEnd;
          _handleLongPressStart(event.position);
        }
      });
    }

    if (appdata.settings[9] == "4") {
      logic.data.scrollManager!.tapDown(event);
    }

    if (logic.tools &&
        (event.position.dy <
                MediaQuery.of(App.globalContext!).padding.top + 50 ||
            MediaQuery.of(App.globalContext!).size.height - event.position.dy <
                105 + MediaQuery.of(App.globalContext!).padding.bottom)) {
      return;
    }

    if (event.buttons == kSecondaryMouseButton) {
      if (logic.showSettings) {
        logic.showSettings = false;
        logic.update();
        return;
      }
      logic.tools = !logic.tools;
      logic.update();
      if (logic.tools) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      return;
    }

    if (!logic.scrollController.hasClients) {
      _tapOffset = event.position;
    } else if (logic.scrollController.hasClients &&
        (DateTime.now() - lastScrollTime).inMilliseconds > 50) {
      _tapOffset = event.position;
    }
  }

  static void Function(PointerUpEvent detail)? _doubleClickRecognizer;

  static void onTapUp(PointerUpEvent detail) async {
    fingers--;
    if(onTapUpReplacement != null){
      onTapUpReplacement!(detail);
      onTapUpReplacement = null;
      return;
    }

    var logic = StateController.find<ComicReadingPageLogic>();

    _tapDownPointer = null;

    if (appdata.settings[9] == "4") {
      logic.data.scrollManager!.tapUp(detail);
    }

    if (_tapOffset != null) {
      var distance = detail.position.dy - _tapOffset!.dy;
      if (distance > 0.1 || distance < -0.1) {
        return;
      }
      _tapOffset = null;
    } else {
      return;
    }

    if (appdata.settings[49] == "1") {
      if (_doubleClickRecognizer == null) {
        bool flag = false;
        _doubleClickRecognizer = (another) {
          var d = detail.delta - another.delta;
          if (d.dx.abs() < 30 && d.dy.abs() < 30) {
            flag = true;
          }
        };
        await Future.delayed(const Duration(milliseconds: 200));
        _doubleClickRecognizer = null;
        if (flag) {
          _handleDoubleClick(detail.position);
          return;
        }
      } else {
        _doubleClickRecognizer!.call(detail);
        return;
      }
    }

    _handleClick(detail, logic, App.globalContext!);
  }

  static void onPointerMove(PointerMoveEvent event){
    final data = StateController.find<ComicReadingPageLogic>().data;
    if(event.pointer == _tapDownPointer?.id){
      _tapDownPointer!.offset += event.delta;
      if(_tapDownPointer!.getDistance() > 1){
        _tapDownPointer = null;
      }
    }
    if (appdata.settings[9] == "4" &&
        data.scrollManager!.fingers != 2) {
      data.scrollManager!.addOffset(event.delta);
    }
  }

  static void _handleClick(PointerUpEvent detail, ComicReadingPageLogic logic,
      BuildContext context) {
    bool flag = false;
    bool flag2 = false;
    final range = int.parse(appdata.settings[40]) / 100;
    if (appdata.settings[0] == "1" && !logic.tools) {
      switch (appdata.settings[9]) {
        case "1":
        case "5":
          detail.position.dx > MediaQuery.of(context).size.width * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dx < MediaQuery.of(context).size.width * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
        case "2":
        case "6":
          detail.position.dx > MediaQuery.of(context).size.width * (1 - range)
              ? logic.jumpToLastPage()
              : flag = true;
          detail.position.dx < MediaQuery.of(context).size.width * range
              ? logic.jumpToNextPage()
              : flag2 = true;
          break;
        case "3":
          detail.position.dy > MediaQuery.of(context).size.height * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dy < MediaQuery.of(context).size.height * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
        case "4":
          detail.position.dy > MediaQuery.of(context).size.height * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dy < MediaQuery.of(context).size.height * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
      }
    } else {
      flag = flag2 = true;
    }
    if (flag && flag2) {
      logic.tools = !logic.tools;
      logic.update(["ToolBar"]);
      if (logic.tools) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    }
  }

  static void _handleDoubleClick(Offset position) async {
    var logic = StateController.find<ComicReadingPageLogic>();
    var controller = logic.photoViewController;
    double target;
    if (controller.scale == null || controller.getInitialScale?.call() == null) {
      return;
    }
    if(!logic.readingMethod.useComicImage){
      controller.onDoubleClick?.call();
      return;
    }
    if(controller.scale != controller.getInitialScale?.call()){
      target = controller.getInitialScale!.call()!;
    } else {
      target = controller.getInitialScale!.call()! * 1.75;
    }
    var size = MediaQuery.of(App.globalContext!).size;
    controller.animateScale?.call(target, Offset(size.width/2 - position.dx, size.height/2 - position.dy));
  }

  static void _handleLongPressStart(Offset position){
    var logic = StateController.find<ComicReadingPageLogic>();
    var controller = logic.photoViewController;
    if(controller.scale != controller.getInitialScale?.call() || controller.scale == null
        || controller.getInitialScale?.call() == null){
      return;
    }
    final target = controller.getInitialScale!.call()! * 1.75;
    var size = MediaQuery.of(App.globalContext!).size;
    controller.animateScale?.call(target, Offset(size.width/2 - position.dx, size.height/2 - position.dy));
    controller.updateState?.call(null);
  }

  static void _handleLongPressEnd(PointerUpEvent event){
    var logic = StateController.find<ComicReadingPageLogic>();
    var controller = logic.photoViewController;
    if(controller.scale == controller.getInitialScale?.call() || controller.scale == null){
      return;
    }
    final target = controller.getInitialScale?.call();
    controller.animateScale?.call(target ?? 1);
    controller.updateState?.call(null);
  }
}
