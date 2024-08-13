import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'accounts_page.dart';
import 'package:pica_comic/pages/download_page.dart';
import 'package:pica_comic/pages/tools.dart';
import 'package:pica_comic/foundation/app.dart';
import 'history_page.dart';
import 'package:pica_comic/tools/translations.dart';
import 'image_favorites.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constrains) {
          final width = constrains.maxWidth;
          bool shouldShowTwoPanel = width > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(
                  height: 12,
                ),
                buildHistory(context),
                if (shouldShowTwoPanel)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 12,
                            ),
                            buildAccount(width),
                            const SizedBox(
                              height: 12,
                            ),
                            buildDownload(context, width),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 12,
                            ),
                            buildImageFavorite(context, width),
                            const SizedBox(
                              height: 12,
                            ),
                            buildTools(width),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  const SizedBox(
                    height: 12,
                  ),
                  buildAccount(width),
                  const SizedBox(
                    height: 12,
                  ),
                  buildDownload(context, width),
                  const SizedBox(
                    height: 12,
                  ),
                  buildImageFavorite(context, width),
                  const SizedBox(
                    height: 12,
                  ),
                  buildTools(width),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildHistory(BuildContext context) {
    var history = HistoryManager().getRecent();
    return InkWell(
      onTap: () => context.to(() => const HistoryPage()),
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.zero,
          width: double.infinity,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: Text("${"历史记录".tl}(${HistoryManager().count()})"),
                trailing: const Icon(Icons.chevron_right),
                mouseCursor: SystemMouseCursors.click,
              ),
              SizedBox(
                height: 128,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () =>
                          toComicPageWithHistory(context, history[index]),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 96,
                        height: 128,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AnimatedImage(
                          image: CachedImageProvider(history[index].cover),
                          width: 96,
                          height: 128,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    );
                  },
                ),
              ).paddingHorizontal(8),
              const SizedBox(
                height: 12,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAccount(double width) {
    var accounts = findAccounts();

    Widget buildItem(String name) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(App.globalContext!).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          name,
          style: const TextStyle(fontSize: 12),
        ).paddingTop(4),
      );
    }

    return _MePageCard(
      icon: const Icon(Icons.switch_account),
      title: "账号管理".tl,
      description: "已登录 @a 个账号".tlParams({"a": accounts.length.toString()}),
      onTap: () => showPopUpWidget(App.globalContext!, const AccountsPage()),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: accounts.map((e) => buildItem(e)).toList(),
      ).paddingHorizontal(12).paddingBottom(12),
    );
  }

  Widget buildDownload(BuildContext context, double width) {
    return _MePageCard(
      icon: const Icon(Icons.download_for_offline),
      title: "已下载".tl,
      description: "共 @a 部漫画"
          .tlParams({"a": DownloadManager().downloaded.length.toString()}),
      onTap: () => context.to(() => const DownloadPage()),
    );
  }

  Widget buildImageFavorite(BuildContext context, double width) {
    return _MePageCard(
      icon: const Icon(Icons.image),
      title: "图片收藏".tl,
      description:
          "@a 条图片收藏".tlParams({"a": ImageFavoriteManager.length.toString()}),
      onTap: () => context.to(() => const ImageFavoritesPage()),
    );
  }

  Widget buildTools(double width) {
    Widget buildItem(String name) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(App.globalContext!).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          name,
          style: const TextStyle(fontSize: 12),
        ).paddingTop(4),
      );
    }

    return _MePageCard(
      icon: const Icon(Icons.build_circle),
      title: "工具".tl,
      description: "使用工具发现更多漫画".tl,
      onTap: openTool,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          buildItem("Eh订阅".tl),
          buildItem("图片搜索".tl),
          buildItem("打开链接".tl),
        ],
      ).paddingHorizontal(12).paddingBottom(12),
    );
  }

  List<String> findAccounts() {
    var result = <String>[];
    for (var source in ComicSource.sources) {
      if (source.isLogin) {
        result.add(source.name);
      }
    }
    return result;
  }
}

class _MePageCard extends StatelessWidget {
  const _MePageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.child,
  });

  final Widget icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card.outlined(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: icon,
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              mouseCursor: SystemMouseCursors.click,
            ),
            Text(description)
                .paddingHorizontal(16)
                .paddingBottom(16)
                .paddingTop(8),
            if (child != null) child!
          ],
        ),
      ),
    );
  }
}
