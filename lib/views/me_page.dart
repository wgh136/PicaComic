import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/app_views/image_favorites.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/tools.dart';
import 'package:pica_comic/views/widgets/animated_image.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';

class OldMePage extends StatelessWidget {
  const OldMePage({super.key});

  int calcAccounts(){
    int count = 0;
    if(appdata.picacgAccount != "") count++;
    if(appdata.ehAccount != "") count++;
    if(appdata.jmName != "") count++;
    if(appdata.htName != "") count++;
    if(NhentaiNetwork().logged) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    StateController.putIfNotExists(SimpleController(), tag: "me_page");
    var controller = ScrollController();
    return LayoutBuilder(builder: (context, constrains){
      final width = constrains.maxWidth;
      int days;
      if(width < 350){
        days = width ~/ 50;
      } else {
        days = 7 + (width - 350) ~/ 60;
      }

      return StateBuilder(
        tag: "me_page",
        builder: (logic){
          int accounts = calcAccounts();
          var padding = 24.0;
          if(UiMode.m1(context)){
            padding /= 3;
          } else if(UiMode.m3(context)){
            padding *= 4;
          }
          return Scrollbar(controller: controller, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                  primary: false,
                  controller: controller,
                  slivers: [
                    if (!UiMode.m1(context))
                      const SliverPadding(padding: EdgeInsets.all(30)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 204,
                        child: Center(
                          child: WeekReport(HistoryManager().getWeekData(days)),
                        ),
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.all(4)),
                    SliverGrid(
                      delegate: SliverChildListDelegate.fixed([
                        MePageButton(
                          title: "账号管理".tl,
                          subTitle: "已登录 @a 个账号".tlParams({"a": accounts.toString()}),
                          icon: Icons.switch_account,
                          onTap: () => showAdaptiveWidget(App.globalContext!,
                              AccountsPage()),
                        ),
                        MePageButton(
                          title: "已下载".tl,
                          subTitle: "共 @a 部漫画".tlParams({"a": DownloadManager().downloaded.length.toString()}),
                          icon: Icons.download_for_offline,
                          onTap: () => MainPage.to(() => const DownloadPage()),
                        ),
                        MePageButton(
                          title: "历史记录".tl,
                          subTitle: "@a 条历史记录".tlParams({"a": appdata.history.length.toString()}),
                          icon: Icons.history,
                          onTap: () => MainPage.to(() => const HistoryPage()),
                        ),
                        MePageButton(
                          title: "图片收藏".tl,
                          subTitle: "@a 条图片收藏".tlParams({"a": ImageFavoriteManager.length.toString()}),
                          icon: Icons.image,
                          onTap: () => MainPage.to(() => const ImageFavoritesPage()),
                        ),
                        MePageButton(
                          title: "工具".tl,
                          subTitle: "使用工具发现更多漫画".tl,
                          icon: Icons.build_circle,
                          onTap: openTool,
                        ),
                      ]),
                      gridDelegate: const MePageItemsDelegate(),
                    ),
                  ]
              ),
            ),
          ));
        },
      );
    });
  }
}

class MePageItemsDelegate extends SliverGridDelegate {
  const MePageItemsDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final items = (constraints.crossAxisExtent / 540).ceil();
    final width = constraints.crossAxisExtent / items;
    final height = (width / 3).clamp(124, 196).toDouble();
    return SliverGridRegularTileLayout(
      crossAxisCount: items,
      mainAxisStride: height,
      crossAxisStride: width,
      childMainAxisExtent: height.clamp(124, 178) - 4,
      childCrossAxisExtent: width,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) {
    return oldDelegate is! MePageItemsDelegate;
  }
}

class WeekReport extends StatelessWidget {
  const WeekReport(this.data, {super.key});

  final List<int> data;

  @override
  Widget build(BuildContext context) {
    var length = data.reduce((value, element) => value + element);
    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt_outlined),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  "最近".tl,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  length.toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                )
              ],
            ),
            const SizedBox(height: 8,),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LineChart(
                  calculateData(context, data),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  LineChartData calculateData(BuildContext context, List<int> data) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    List<Color> gradientColors = [
      dark ? Colors.blue : Colors.pink,
      Theme.of(context).colorScheme.surface,
    ];
    final current = DateTime.now();
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          spots: [
            for (int i = 0; i < data.length; i++)
              FlSpot(
                  i.toDouble(),
                  data.elementAt(i).toDouble()),
          ],
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
              ],
            ),
          ),
          isStepLineChart: true,
        ),
      ],
      minX: 0,
      maxX: data.length-1,
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, child) {
                  final time = current.add(Duration(days: (1-data.length) + value.toInt()));
                  return Text("${time.month}/${time.day}");
                })),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: const FlGridData(
          show: false,
          drawHorizontalLine: false,
          drawVerticalLine: false
      ),
      borderData: FlBorderData(
        show: false,
      ),
    );
  }
}


class MePageButton extends StatefulWidget {
  const MePageButton({required this.title, required this.subTitle, required this.icon, required this.onTap, super.key});

  final String title;
  final String subTitle;
  final IconData icon;
  final void Function() onTap;

  @override
  State<MePageButton> createState() => _MePageButtonState();
}

class _MePageButtonState extends State<MePageButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          onPointerCancel: (event) => setState(() => hovering = false),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: widget.onTap,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  color: hovering?Theme.of(context).colorScheme.inversePrimary.withAlpha(150):Theme.of(context).colorScheme.inversePrimary.withAlpha(40)
              ),
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(widget.subTitle, style: const TextStyle(fontSize: 15),),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipPath(
                        clipper: MePageIconClipper(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: hovering?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surface,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(widget.icon, color: hovering?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface,),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MePageIconClipper extends CustomClipper<Path>{
  @override
  Path getClip(Size size) {
    final path = Path();
    final r = size.width * 0.3; // 控制弧线的大小

    // 起始点
    path.moveTo(r, 0);

    // 上边弧线
    path.arcToPoint(
      Offset(size.width - r, 0),
      radius: Radius.circular(r * 2),
      clockwise: false,
    );

    // 右上角圆弧
    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 右边弧线
    path.arcToPoint(
      Offset(size.width, size.height - r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 右下角圆弧
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 下边弧线
    path.arcToPoint(
      Offset(r, size.height),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左下角圆弧
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 左边弧线
    path.arcToPoint(
      Offset(0, r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左上角圆弧
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}


class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constrains){
          final width = constrains.maxWidth;
          bool shouldShowTwoPanel = width > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const SizedBox(height: 12,),
                buildHistory(),
                if(shouldShowTwoPanel)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 12,),
                            buildAccount(width),
                            const SizedBox(height: 12,),
                            buildDownload(width),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12,),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 12,),
                            buildImageFavorite(width),
                            const SizedBox(height: 12,),
                            buildTools(width),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  const SizedBox(height: 12,),
                  buildAccount(width),
                  const SizedBox(height: 12,),
                  buildDownload(width),
                  const SizedBox(height: 12,),
                  buildImageFavorite(width),
                  const SizedBox(height: 12,),
                  buildTools(width),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildHistory(){
    var history = HistoryManager().getRecent();
    return InkWell(
      onTap: () => MainPage.to(() => const HistoryPage()),
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
                      onTap: () => toComicPageWithHistory(history[index]),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 96,
                        height: 128,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.secondaryContainer,
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
              const SizedBox(height: 12,)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAccount(double width){
    return _MePageCard(
      icon: const Icon(Icons.switch_account),
      title: "账号管理".tl,
      description: "已登录 @a 个账号".tlParams({"a": calcAccounts().toString()}),
      onTap: () => showAdaptiveWidget(App.globalContext!, AccountsPage()),
    );
  }

  Widget buildDownload(double width){
    return _MePageCard(
      icon: const Icon(Icons.download_for_offline),
      title: "已下载".tl,
      description: "共 @a 部漫画".tlParams({"a": DownloadManager().downloaded.length.toString()}),
      onTap: () => MainPage.to(() => const DownloadPage()),
    );
  }

  Widget buildImageFavorite(double width){
    return _MePageCard(
      icon: const Icon(Icons.image),
      title: "图片收藏".tl,
      description: "@a 条图片收藏".tlParams({"a": ImageFavoriteManager.length.toString()}),
      onTap: () => MainPage.to(() => const ImageFavoritesPage()),
    );
  }

  Widget buildTools(double width){
    return _MePageCard(
      icon: const Icon(Icons.build_circle),
      title: "工具".tl,
      description: "使用工具发现更多漫画".tl,
      onTap: openTool,
    );
  }

  int calcAccounts(){
    int count = 0;
    if(appdata.picacgAccount != "") count++;
    if(appdata.ehAccount != "") count++;
    if(appdata.jmName != "") count++;
    if(appdata.htName != "") count++;
    if(NhentaiNetwork().logged) count++;
    return count;
  }
}

class _MePageCard extends StatelessWidget {
  const _MePageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String description;
  final VoidCallback onTap;

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
            Text(description).paddingHorizontal(16).paddingBottom(16).paddingTop(8),
          ],
        ),
      ),
    );
  }
}
