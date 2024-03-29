import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';


class LoadingDialogController {
  void Function()? closeDialog;

  bool closed = false;

  void close() {
    if (closed) {
      return;
    }
    closed = true;
    if (closeDialog == null) {
      Future.microtask(closeDialog!);
    } else {
      closeDialog!();
    }
  }
}

LoadingDialogController showLoadingDialog(
    BuildContext context, void Function() onCancel,
    [bool barrierDismissible = true,
    bool allowCancel = true,
    String? message,
    String cancelButtonText = "取消"]) {
  var controller = LoadingDialogController();

  var loadingDialogRoute = DialogRoute(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
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
                        controller.close();
                        onCancel();
                      },
                      child: Text(cancelButtonText.tl))
              ],
            ),
          ),
        );
      });

  Navigator.of(context).push(loadingDialogRoute)
      .then((value) => controller.closed = true);

  controller.closeDialog = () {
    Navigator.of(context).removeRoute(loadingDialogRoute);
  };

  return controller;
}
