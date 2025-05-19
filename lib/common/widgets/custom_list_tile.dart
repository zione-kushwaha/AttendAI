import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final bool isThreeLine;

  const CustomListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onTap,
    this.isThreeLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                )
                : null,
        leading: leading,
        trailing:
            actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,
        onTap: onTap,
        isThreeLine: isThreeLine,
      ),
    );
  }
}
