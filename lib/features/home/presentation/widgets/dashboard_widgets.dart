import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';

/// A rounded, subtly outlined surface used for every dashboard section.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
    );
    return Material(
      color: color ?? scheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A small label pill, e.g. "LAN / Wi-Fi" or "12 available".
class TagPill extends StatelessWidget {
  const TagPill(this.text,
      {super.key,
      this.icon,
      this.color,
      this.textColor,
      this.translate = true});

  final String text;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  /// False for text that must be shown as is, such as a language name.
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: textColor ?? theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: style?.color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: translate
                ? LocalText(text, style: style, maxLines: 1)
                : Text(text, style: style, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

/// A rounded square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 36});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.55, color: scheme.onSurface),
    );
  }
}

/// A section heading such as "HOW TO PLAY" or "GAME HUB".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: LocalText(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}
