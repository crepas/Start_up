import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;

  CommonAppBar({required this.title, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: MediaQuery.of(context).size.width * 0.04,
          fontWeight: FontWeight.w400,
          color: theme.appBarTheme.foregroundColor,
        ),
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: theme.appBarTheme.elevation,
      toolbarHeight: MediaQuery.of(context).size.height * 0.07,
      leading: onBackPressed != null
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
