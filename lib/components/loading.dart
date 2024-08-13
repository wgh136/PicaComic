part of 'components.dart';

class NetworkError extends StatelessWidget {
  const NetworkError({
    super.key,
    required this.message,
    this.retry,
    this.withAppbar = true,
  });

  final String message;

  final void Function()? retry;

  final bool withAppbar;

  @override
  Widget build(BuildContext context) {
    Widget body = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          if (retry != null)
            const SizedBox(
              height: 4,
            ),
          if (retry != null)
            if (message == NhentaiNetwork.needCloudflareChallengeMessage)
              FilledButton(
                onPressed: () => bypassCloudFlare(retry!),
                child: Text('继续'.tl),
              )
            else
              FilledButton(onPressed: retry, child: Text('重试'.tl))
        ],
      ),
    );
    if (withAppbar) {
      body = Column(
        children: [
          const Appbar(title: Text("")),
          Expanded(
            child: body,
          )
        ],
      );
    }
    return Material(
      child: body,
    );
  }
}

class ListLoadingIndicator extends StatelessWidget {
  const ListLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Text("${"加载中".tl}...")
            ],
          ),
        ),
      ),
    );
  }
}

abstract class LoadingState<T extends StatefulWidget, S extends Object>
    extends State<T> {
  bool isLoading = false;

  S? data;

  String? error;

  Future<Res<S>> loadData();

  Widget buildContent(BuildContext context, S data);

  Widget? buildFrame(BuildContext context, Widget child) => null;

  Widget buildLoading() {
    return Center(
      child: const CircularProgressIndicator(
        strokeWidth: 2,
      ).fixWidth(32).fixHeight(32),
    );
  }

  void retry() {
    setState(() {
      isLoading = true;
      error = null;
    });
    loadData().then((value) {
      if (value.success) {
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
          Text(
            error!,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Button.text(
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
    Future.microtask(() {
      loadData().then((value) {
        if (value.success) {
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
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (isLoading) {
      child = buildLoading();
    } else if (error != null) {
      child = buildError();
    } else {
      child = buildContent(context, data!);
    }

    return buildFrame(context, child) ?? child;
  }
}

abstract class MultiPageLoadingState<T extends StatefulWidget, S extends Object>
    extends State<T> {
  bool _isFirstLoading = true;

  bool _isLoading = false;

  List<S>? data;

  String? _error;

  int _page = 1;

  int _maxPage = 1;

  Future<Res<List<S>>> loadData(int page);

  Widget? buildFrame(BuildContext context, Widget child) => null;

  Widget buildContent(BuildContext context, List<S> data);

  bool get isLoading => _isLoading || _isFirstLoading;

  bool get isFirstLoading => _isFirstLoading;

  bool get haveNextPage => _page <= _maxPage;

  void nextPage() {
    if (_page > _maxPage) return;
    if (_isLoading) return;
    _isLoading = true;
    loadData(_page).then((value) {
      _isLoading = false;
      if (mounted) {
        if (value.success) {
          _page++;
          if (value.subData is int) {
            _maxPage = value.subData as int;
          }
          setState(() {
            data!.addAll(value.data);
          });
        } else {
          var message = value.errorMessage ?? "Network Error";
          if (message.length > 20) {
            message = "${message.substring(0, 20)}...";
          }
          context.showMessage(message: message);
        }
      }
    });
  }

  void reset() {
    setState(() {
      _isFirstLoading = true;
      _isLoading = false;
      data = null;
      _error = null;
      _page = 1;
    });
    firstLoad();
  }

  void firstLoad() {
    Future.microtask(() {
      loadData(_page).then((value) {
        if (!mounted) return;
        if (value.success) {
          _page++;
          if (value.subData is int) {
            _maxPage = value.subData as int;
          }
          setState(() {
            _isFirstLoading = false;
            data = value.data;
          });
        } else {
          setState(() {
            _isFirstLoading = false;
            _error = value.errorMessage!;
          });
        }
      });
    });
  }

  @override
  void initState() {
    firstLoad();
    super.initState();
  }

  Widget buildLoading(BuildContext context) {
    return Center(
      child: const CircularProgressIndicator(
        strokeWidth: 2,
      ).fixWidth(32).fixHeight(32),
    );
  }

  Widget buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error, maxLines: 3),
          const SizedBox(height: 12),
          Button.outlined(
            onPressed: () {
              reset();
            },
            child: const Text("Retry"),
          )
        ],
      ),
    ).paddingHorizontal(16);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isFirstLoading) {
      child = buildLoading(context);
    } else if (_error != null) {
      child = buildError(context, _error!);
    } else {
      child = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels ==
              notification.metrics.maxScrollExtent) {
            nextPage();
          }
          return false;
        },
        child: buildContent(context, data!),
      );
    }

    return buildFrame(context, child) ?? child;
  }
}
