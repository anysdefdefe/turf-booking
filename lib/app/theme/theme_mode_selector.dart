import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ThemeModeSelector extends StatelessWidget {
  final bool compact;
  final String? title;

  const ThemeModeSelector({super.key, this.compact = false, this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
            ],
            _ModeControl(
              mode: mode,
              compact: compact,
              brightness: brightness,
            ),
          ],
        );
      },
    );
  }
}

class _ModeControl extends StatelessWidget {
  final ThemeMode mode;
  final bool compact;
  final Brightness brightness;

  const _ModeControl({
    required this.mode,
    required this.compact,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final modes = <ThemeMode, ({IconData icon, String label, String tooltip})>{
      ThemeMode.light: (
        icon: Icons.light_mode_rounded,
        label: 'Light',
        tooltip: 'Light',
      ),
      ThemeMode.dark: (
        icon: Icons.dark_mode_rounded,
        label: 'Dark',
        tooltip: 'Dark',
      ),
      ThemeMode.system: (
        icon: Icons.brightness_auto_rounded,
        label: 'System',
        tooltip: 'Match device',
      ),
    };
    final orderedModes = ThemeMode.values;
    final selectedIndex = orderedModes.indexOf(mode);
    final controlHeight = compact ? 44.0 : 52.0;
    final controlWidth = compact ? 248.0 : 320.0;
    final outerRadius = BorderRadius.circular(compact ? 999 : 22);
    final innerPadding = compact ? 4.0 : 5.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final controlWidthValue = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(0.0, controlWidth).toDouble()
            : controlWidth;

        return ClipRRect(
          borderRadius: outerRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: controlWidthValue,
              height: controlHeight,
              decoration: BoxDecoration(
                gradient: brightness == Brightness.dark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          cs.surfaceContainerLowest.withValues(alpha: 0.92),
                        ],
                      ),
                borderRadius: outerRadius,
                border: Border.all(
                  color: brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : cs.outlineVariant.withValues(alpha: 0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(innerPadding),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: switch (selectedIndex) {
                        0 => Alignment.centerLeft,
                        1 => Alignment.center,
                        _ => Alignment.centerRight,
                      },
                      child: FractionallySizedBox(
                        widthFactor: 1 / 3,
                        heightFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              compact ? 999 : 18,
                            ),
                            gradient: brightness == Brightness.dark
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cs.surfaceContainerHighest,
                                      cs.surfaceContainerHigh,
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      cs.primaryContainer.withValues(alpha: 0.5),
                                    ],
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: orderedModes.map((itemMode) {
                        final entry = modes[itemMode]!;
                        final selected = itemMode == mode;
                        return Expanded(
                          child: _ModeSegment(
                            icon: entry.icon,
                            label: entry.label,
                            tooltip: entry.tooltip,
                            compact: compact,
                            selected: selected,
                            onTap: () => ThemeController.instance
                                .setThemeMode(itemMode),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 999 : 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 9 : 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0.8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: compact ? 18 : 20,
                    color: selected ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
