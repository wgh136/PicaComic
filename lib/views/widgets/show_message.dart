import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';

OverlayEntry? entry;

/// show message
void showMessage(BuildContext? context, String message,
    {int time = 2, bool useGet = true, Widget? action}) {
  var padding = MediaQuery.of(App.globalContext!).size.width - 400;
  if (padding < 32) {
    padding = 32;
  }

  if (entry != null && entry!.mounted) {
    entry!.remove();
  }

  var newEntry = OverlayEntry(
      builder: (context) => Positioned(
            bottom: 24,
            left: padding / 2,
            right: padding / 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: 48, maxHeight: 104),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                        child: Text(
                      message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      maxLines: 3,
                    )),
                    if (action != null) action,
                    const SizedBox(
                      width: 8,
                    )
                  ],
                ),
              ),
            ),
          ));

  Future.delayed(Duration(seconds: time), () {
    if (newEntry.mounted) {
      newEntry.remove();
    }
  });

  Overlay.of(App.globalContext!).insert(newEntry);
  entry = newEntry;
}

void hideMessage(BuildContext? context) {
  if (entry?.mounted ?? false) {
    entry?.remove();
  }
}

void showDialogMessage(BuildContext context, String title, String message) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => App.back(context), child: Text("了解".tl))
            ],
          ));
}

void showConfirmDialog(BuildContext context, String title, String content,
    void Function() onConfirm) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => App.back(context), child: Text("取消".tl)),
              TextButton(
                  onPressed: () {
                    App.back(context);
                    onConfirm();
                  },
                  child: Text("确认".tl)),
            ],
          ));
}
