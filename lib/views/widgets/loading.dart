import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';

Widget showLoading(BuildContext context, {bool withScaffold = false}) {
  final loading = Lottie.asset("images/loading.json",
      width: 180,
      height: 180,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.strokeColor(
            const ['**'],
            value: Theme.of(context).colorScheme.primary,
          ),
          ValueDelegate.color(
            const ['**'],
            value: Theme.of(context).colorScheme.primary,
          )
        ],
      ));

  if (withScaffold) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: loading,
      ),
    );
  } else {
    return Center(
      child: SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading,
            const SizedBox(
              height: 16,
            ),
            Center(
              child: Text("加载中".tl),
            ),
            const SizedBox(
              height: 4,
            ),
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("取消".tl))
          ],
        ),
      ),
    );
  }
}

class LoadingDialogController {
  BuildContext? context;

  void close() {
    if (context == null) {
      Future.microtask(() => Navigator.of(context!).pop());
    } else {
      Navigator.of(context!).pop();
    }
  }
}

LoadingDialogController showLoadingDialog(
    BuildContext context, void Function() onCancel,
    [bool barrierDismissible = true,
    bool allowCancel = true,
    String? message]) {
  var controller = LoadingDialogController();
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      controller.context = context;
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  message ?? 'Loading',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                if (allowCancel)
                  TextButton(
                      onPressed: () {
                        App.globalBack();
                        onCancel();
                      },
                      child: Text("取消".tl))
              ],
            ),
          ),
        ),
      );
    },
  );
  return controller;
}
