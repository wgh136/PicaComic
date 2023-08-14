import "package:flutter/material.dart";

/// copied from flutter source
class _NavigationBarDefaultsM3 extends NavigationBarThemeData {
  _NavigationBarDefaultsM3(this.context)
      : super(
    height: 80.0,
    elevation: 3.0,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override Color? get backgroundColor => _colors.surface;

  @override Color? get shadowColor => Colors.transparent;

  @override Color? get surfaceTintColor => _colors.surfaceTint;

  @override MaterialStateProperty<IconThemeData?>? get iconTheme {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      return IconThemeData(
        size: 24.0,
        color: states.contains(MaterialState.selected)
            ? _colors.onSecondaryContainer
            : _colors.onSurfaceVariant,
      );
    });
  }

  @override Color? get indicatorColor => _colors.secondaryContainer;
  @override ShapeBorder? get indicatorShape => const StadiumBorder();

  @override MaterialStateProperty<TextStyle?>? get labelTextStyle {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      final TextStyle style = _textTheme.labelMedium!;
      return style.apply(color: states.contains(MaterialState.selected)
          ? _colors.onSurface
          : _colors.onSurfaceVariant
      );
    });
  }
}

typedef SelectedCallback = void Function(int);

class CustomNavigationBar extends StatefulWidget {
  /// Create a M3 NavigationBar
  ///
  /// It have no difference from flutter's NavigationBar in appearance.
  ///
  /// However, flutter's NavigationBar must be provided to Scaffold parameter bottomNavigationBar,
  /// otherwise it will cause Ui error.
  ///
  /// This is used at the end of a Column.
  const CustomNavigationBar({required this.destinations, required this.onDestinationSelected, required this.selectedIndex, super.key});

  final SelectedCallback onDestinationSelected;

  final List<NavigationItemData> destinations;

  final int selectedIndex;

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late List<bool> hover = List<bool>.generate(widget.destinations.length, (index) => false);

  @override
  Widget build(BuildContext context) {
    final NavigationBarThemeData navigationBarTheme = _NavigationBarDefaultsM3(context);
    return Material(
      textStyle: Theme.of(context).textTheme.labelSmall,
      elevation: navigationBarTheme.elevation ?? 3,
      shadowColor: navigationBarTheme.shadowColor,
      surfaceTintColor: navigationBarTheme.surfaceTintColor,
      color: navigationBarTheme.backgroundColor,
      child: SizedBox(
        height: 80 + MediaQuery.of(context).padding.bottom,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Row(
            children: List<Widget>.generate(widget.destinations.length, (index) => Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (details) => setState(() => hover[index] = true),
                onExit: (details) => setState(() => hover[index] = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => widget.onDestinationSelected(index),
                  child: NavigationItem(
                    data: widget.destinations[index],
                    selected: index == widget.selectedIndex,
                    hover: hover[index],
                  ),
                ),
              )
            )),
          ),
        ),
      )
    );
  }
}

class NavigationItemData{
  const NavigationItemData({required this.icon, required this.selectedIcon, required this.label});

  final Icon icon;

  final Icon selectedIcon;

  final String label;
}

class NavigationItem extends StatelessWidget {
  NavigationItem({required NavigationItemData data, required this.selected, required this.hover, super.key}):
      icon = data.icon,
      selectedIcon = data.selectedIcon,
      label = data.label;

  final Icon icon;

  final Icon selectedIcon;

  final String label;

  final bool selected;

  final bool hover;

  @override
  Widget build(BuildContext context) {
    var finalIcon = selected ? selectedIcon : icon;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      child: Center(
        child: SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12,),
              Container(
                width: 64,
                height: 32,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(32)),
                    color: selected ? colorScheme.secondaryContainer : (hover ? colorScheme.surfaceVariant : null)
                ),
                child: Center(
                    child: Icon(
                      finalIcon.icon,
                      size: 24,
                    )
                ),
              ),
              const SizedBox(height: 4,),
              Text(label),
              const SizedBox(height: 16,),
            ],
          ),
        ),
      ),
    );
  }
}
