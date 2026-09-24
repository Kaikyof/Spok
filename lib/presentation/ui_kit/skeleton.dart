import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';

/// Заглушка строки на время загрузки.
///
/// Скелет держит ту же высоту и то же место, что будущий блок: когда данные
/// приходят, ничего не прыгает и человек не теряет то, на что смотрел.
/// Крутящийся индикатор в центре экрана этого не даёт — он ещё и стирает
/// раскладку, к которой человек уже привык (борд 19).
class SkeletonLine extends StatefulWidget {
  final double width;
  final double height;

  /// Ширина в долях строки, если точная неизвестна: `null` — по месту.
  final double? widthFactor;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 11,
    this.widthFactor,
  });

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = FadeTransition(
      // Медленное дыхание, а не бегущий блик: скелет говорит «ещё грузится»,
      // а не требует на себя внимания.
      opacity: Tween(begin: 0.45, end: 0.85).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.cardHighlight,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    final factor = widget.widthFactor;
    return factor == null
        ? line
        : FractionallySizedBox(
            alignment: Alignment.centerLeft, widthFactor: factor, child: line);
  }
}

/// Строка таблицы на время загрузки: высота и отступы — как у настоящей,
/// поэтому таблица не меняет высоту, когда данные приходят.
class SkeletonRow extends StatelessWidget {
  /// Доли ширины колонок — те же flex, что у настоящей таблицы.
  final List<int> columnFlex;

  /// Заполненность колонки: подписи бывают короче ширины колонки.
  final List<double> widthFactors;

  final bool showTopDivider;
  final EdgeInsets padding;

  const SkeletonRow({
    super.key,
    required this.columnFlex,
    this.widthFactors = const [],
    this.showTopDivider = false,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          border: showTopDivider
              ? const Border(top: BorderSide(color: AppColors.borderSoft))
              : null,
        ),
        child: Row(
          children: [
            for (final (index, flex) in columnFlex.indexed)
              Expanded(
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppDimens.gapM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(
                          widthFactor: index < widthFactors.length
                              ? widthFactors[index]
                              : 0.7),
                      const SizedBox(height: 6),
                      SkeletonLine(
                          height: 9,
                          widthFactor: index < widthFactors.length
                              ? widthFactors[index] * 0.6
                              : 0.4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
