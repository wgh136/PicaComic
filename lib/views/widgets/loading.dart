import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';

import '../../network/res.dart';


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

abstract class LoadingState<T extends StatefulWidget, S extends Object> extends State<T>{
  bool isLoading = false;

  S? data;

  String? error;

  Future<Res<S>> loadData();

  Widget buildContent(BuildContext context, S data);

  Widget? buildFrame(BuildContext context, Widget child) => null;

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  void retry() {
    setState(() {
      isLoading = true;
      error = null;
    });
    loadData().then((value) {
      if(value.success) {
        setState(() {
          isLoading = false;
          data = value.data;
        });
      } else {
        setState(() {
          isLoading = false;
          error = value.errorMessage!;
        });
      }
    });
  }

  Widget buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error!),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: retry,
            child: const Text("Retry"),
          )
        ],
      ),
    ).paddingHorizontal(16);
  }

  @override
  @mustCallSuper
  void initState() {
    isLoading = true;
    loadData().then((value) {
      if(value.success) {
        setState(() {
          isLoading = false;
          data = value.data;
        });
      } else {
        setState(() {
          isLoading = false;
          error = value.errorMessage!;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if(isLoading){
      child = buildLoading();
    } else if (error != null){
      child = buildError();
    } else {
      child = buildContent(context, data!);
    }

    return buildFrame(context, child) ?? child;
  }
}