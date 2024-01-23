import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/app_views/image_favorites.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/tools.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

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
    return StateBuilder(
      tag: "me_page",
      builder: (controller){
        int accounts = calcAccounts();
        var padding = 24.0;
        if(UiMode.m1(context)){
          padding /= 3;
        } else if(UiMode.m3(context)){
          padding *= 4;
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
          child: CustomScrollView(
              key: const Key("1"),
              slivers: [
                if (!UiMode.m1(context))
                  const SliverPadding(padding: EdgeInsets.all(30))
                else
                  const SliverPadding(padding: EdgeInsets.all(4)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 204,
                    child: Center(
                      child: WeekReport(HistoryManager().getWeekData()),
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.all(8)),
                SliverGrid(
                  delegate: SliverChildListDelegate.fixed([
                    MePageButton(
                      title: "账号管理".tl,
                      subTitle: "已登录 @a 个账号".tlParams({"a": accounts.toString()}),
                      icon: Icons.switch_account,
                      onTap: () => showAdaptiveWidget(App.globalContext!,
                          AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,)),
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
                      icon: Icons.history,
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
        );
      },
    );
  }
}

class MePageItemsDelegate extends SliverGridDelegate {
  const MePageItemsDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final items = (constraints.crossAxisExtent / 600).ceil();
    final width = constraints.crossAxisExtent / items;
    final height = (width / 3).clamp(146, 196).toDouble();
    return SliverGridRegularTileLayout(
      crossAxisCount: items,
      mainAxisStride: height,
      crossAxisStride: width,
      childMainAxisExtent: height,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        elevation: 1,
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
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
                    "近7天".tl,
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
      ),
    );
  }

  LineChartData calculateData(BuildContext context, List<int> data) {
    List<Color> gradientColors = [
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.surface,
    ];
    final current = DateTime.now();
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          spots: [
            for (int i = 0; i < 7; i++)
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
          //isStepLineChart: true,
        ),
      ],
      minX: 0,
      maxX: 6,
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, child) {
                  final time = current.add(Duration(days: -6 + value.toInt()));
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          onPointerCancel: (event) => setState(() => hovering = false),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: widget.onTap,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
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