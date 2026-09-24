import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';

/// Чем место отвечает на наведение мыши.
enum HoverEffect {
  /// Плёнка поверх всей области — для строк, карточек и пунктов меню.
  fill,

  /// Подчёркивание текста — для ссылок внутри текста, где плёнка выглядела
  /// бы случайной подсветкой.
  underline,
}

/// Нажимаемое место, которое видно мышью: курсор-палец и подсветка под
/// курсором.
///
/// Вместо `InkWell`. Чернила Material рисуются на ближайшем `Material`
/// -предке, а у нас почти каждая строка и карточка лежит в своём
/// `Container` с непрозрачным фоном — подсветка уходила под этот фон и не
/// была видна вовсе. Поэтому рисуем сами: `foregroundDecoration` кладёт
/// плёнку поверх содержимого и не зависит от того, чем закрашен фон.
///
/// Курсор тоже задаём явно: человек понимает, что на это можно нажать, по
/// курсору раньше, чем по цвету.
class Tappable extends StatefulWidget {
  final VoidCallback? onTap;

  /// Скругление плёнки — под скругление самой карточки или строки.
  final BorderRadius? borderRadius;

  final HoverEffect effect;

  /// Подсказка при наведении; null — без подсказки.
  final String? tooltip;

  /// Нажатие ловит кто-то выше — например `PopupMenuButton`, внутри
  /// которого мы лежим. Тогда обработчика у нас нет, а курсор и подсветка
  /// нужны: нажимаемость от этого не меньше.
  final bool tapHandledAbove;

  final Widget child;

  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.effect = HoverEffect.fill,
    this.tooltip,
    this.tapHandledAbove = false,
  });

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _hovered = false;

  /// Выключенное место не обещает нажатия: ни курсора, ни подсветки.
  bool get _enabled => widget.onTap != null || widget.tapHandledAbove;

  @override
  Widget build(BuildContext context) {
    final active = _hovered && _enabled;
    Widget content = widget.child;
    if (widget.effect == HoverEffect.underline) {
      content = DefaultTextStyle.merge(
        style: TextStyle(
            decoration:
                active ? TextDecoration.underline : TextDecoration.none),
        child: content,
      );
    } else {
      content = Container(
        foregroundDecoration: active
            ? BoxDecoration(
                color: AppColors.hoverOverlay,
                borderRadius: widget.borderRadius,
              )
            : null,
        child: content,
      );
    }
    final tooltip = widget.tooltip;
    if (tooltip != null) {
      content = Tooltip(message: tooltip, child: content);
    }
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // Нажатие ловим и на прозрачных участках строки: человек метит
      // в строку целиком, а не в надпись внутри неё. Когда жест забирает
      // родитель, своего распознавателя не ставим вовсе — иначе он съест
      // нажатие у него.
      child: widget.tapHandledAbove
          ? content
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: content,
            ),
    );
  }
}
