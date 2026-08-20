import 'package:flutter/material.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';

/// Одна строка подсказки: значение моноширинным и пояснение рядом.
class SuggestionItem {
  final String value;
  final String description;

  const SuggestionItem(this.value, this.description);
}

/// Список подсказок с выделением активной строки (навигация стрелками).
/// Растёт по содержимому: ограничение высоты и прокрутку задаёт вызывающий,
/// поэтому список одинаково работает и на странице, и во всплывающей панели.
class SuggestionList extends StatelessWidget {
  final List<SuggestionItem> items;
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final String? header;
  final String? footer;
  final double valueWidth;

  const SuggestionList({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelected,
    this.header,
    this.footer,
    this.valueWidth = 180,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(header!,
                  style: AppTextStyles.sectionLabel.copyWith(fontSize: 9.5)),
            ),
          for (final (index, item) in items.indexed)
            _SuggestionRow(
              item: item,
              active: index == activeIndex,
              valueWidth: valueWidth,
              onTap: () => onSelected(index),
            ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Text(footer!, style: AppTextStyles.hint),
            ),
        ],
      );
}

class _SuggestionRow extends StatelessWidget {
  final SuggestionItem item;
  final bool active;
  final double valueWidth;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.item,
    required this.active,
    required this.valueWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          color: active ? AppColors.accentDim : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: valueWidth,
                child: Text(item.value,
                    style: AppTextStyles.monospace(12,
                        color: AppColors.accent,
                        weight: active ? FontWeight.w700 : FontWeight.w400)),
              ),
              const SizedBox(width: AppDimens.gapM),
              Expanded(
                child: Text(item.description,
                    style: AppTextStyles.caption.copyWith(height: 1.4)),
              ),
            ],
          ),
        ),
      );
}
