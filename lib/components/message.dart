part of "components.dart";

void hideAllMessages() {
  _OverlayWidgetState.removeAll();
}

void showToast({required String message, Widget? icon, Widget? trailing}) {
  var newEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
            message: message,
            icon: icon,
            trailing: trailing,
          ));

  _OverlayWidgetState.addOverlay(newEntry);

  Timer(const Duration(seconds: 2), () => _OverlayWidgetState.remove(newEntry));
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({required this.message, this.icon, this.trailing});

  final String message;

  final Widget? icon;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) icon!.paddingRight(8),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  maxLines: 3,
                ),
                if (trailing != null) trailing!.paddingLeft(8)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget(this.child, {super.key});

  final Widget child;

  static void addOverlay(OverlayEntry entry) =>
      _OverlayWidgetState.addOverlay(entry);

  static void removeAll() => _OverlayWidgetState.removeAll();

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  static var overlayKey = GlobalKey<OverlayState>();

  static var entries = <OverlayEntry>[];

  static void addOverlay(OverlayEntry entry) {
    if (overlayKey.currentState != null) {
      overlayKey.currentState!.insert(entry);
      entries.add(entry);
    }
  }

  static void remove(OverlayEntry entry) {
    if (entries.remove(entry)) {
      entry.remove();
    }
  }

  static void removeAll() {
    for (var entry in entries) {
      entry.remove();
    }
    entries.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: overlayKey,
      initialEntries: [OverlayEntry(builder: (context) => widget.child)],
    );
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

LoadingDialogController showLoadingDialog(BuildContext context,
    {void Function()? onCancel,
    bool barrierDismissible = true,
    bool allowCancel = true,
    String? message,
    String cancelButtonText = "Cancel"}) {
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
                        onCancel?.call();
                      },
                      child: Text(cancelButtonText.tl))
              ],
            ),
          ),
        );
      });

  Navigator.of(context)
      .push(loadingDialogRoute)
      .then((value) => controller.closed = true);

  controller.closeDialog = () {
    Navigator.of(context).removeRoute(loadingDialogRoute);
  };

  return controller;
}
