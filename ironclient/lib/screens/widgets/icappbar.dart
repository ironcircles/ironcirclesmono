import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';

class ICAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Function? pop;
  final Widget? bottom;
  final bool leadingIndicator;

  const ICAppBar({
    required this.title,
    this.actions,
    this.pop,
    this.bottom,
    this.leadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
        elevation: 0,
        toolbarHeight: 45,
        centerTitle: false,
        titleSpacing: 0.0,
        iconTheme: IconThemeData(
          color: globalState.theme.menuIcons, //change your color here
        ),
        backgroundColor: globalState.theme.appBar,
        title: Text(title,
            textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
            style: ICTextStyle.getStyle(context: context, 
                color: globalState.theme.textTitle,
                fontSize: ICTextStyle.appBarFontSize)),
        leading: leadingIndicator ? IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => pop != null ? pop!() : Navigator.pop(context),
        ) : null,
        actions: actions,
        bottom: bottom == null
            ? null
            : PreferredSize(
                preferredSize: Size(MediaQuery.of(context).size.width, 30.0),
                child: bottom!,
              ));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ICAppBarTransparent extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const ICAppBarTransparent({
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 45,
      centerTitle: false,
      titleSpacing: 0.0,
      iconTheme: IconThemeData(
        color: globalState.theme.menuIcons, //change your color here
      ),
      backgroundColor: globalState.theme.appBar.withOpacity(.2),
      title: Text(title,
          textScaler: TextScaler.linear(globalState.screenNameScaleFactor),
          style: ICTextStyle.getStyle(context: context, 
              color: globalState.theme.textTitle,
              fontSize: ICTextStyle.appBarFontSize)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 30),
        onPressed: () => Navigator.pop(context),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
