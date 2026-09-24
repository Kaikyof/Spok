import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/resources/app_colors.dart';
import '../../core/resources/app_dimens.dart';
import '../../core/resources/app_text_styles.dart';
import '../../domain/entities/env_field.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bloc/console_bloc.dart';
import '../localization/text_formatters.dart';

/// «Нет доступа — ключ не заполнен у меня»: компактный блок с полем прямо
/// в нём (борд 19).
///
/// Отправлять человека в форму ключей за одним значением — лишний переход:
/// он уже стоит там, где увидел нехватку, и ключ у него под рукой.
/// Спека при этом не при чём: ключ личный, и блок говорит это прямо.
class MissingKeyBlock extends StatefulWidget {
  /// Ключи `.env`, которых не хватает; поле показывается для каждого.
  final List<String> keys;

  /// Где искали — путь и имя ключа, как их собрал `FeatureGate`.
  final String lookedIn;

  const MissingKeyBlock({super.key, required this.keys, this.lookedIn = ''});

  @override
  State<MissingKeyBlock> createState() => _MissingKeyBlockState();
}

class _MissingKeyBlockState extends State<MissingKeyBlock> {
  late final Map<String, TextEditingController> _controllers = {
    for (final key in widget.keys) key: TextEditingController(),
  };
  final _revealed = <String>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Пустые поля не отправляем: пустое значение убирает ключ из `.env`,
  /// а человек мог заполнить только один ключ из трёх.
  Map<String, String> get _filled => {
        for (final entry in _controllers.entries)
          if (entry.value.text.trim().isNotEmpty)
            entry.key: entry.value.text.trim(),
      };

  void _save() {
    final values = _filled;
    if (values.isEmpty) return;
    context.read<ConsoleBloc>().add(EnvSaved(values));
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    return BlocBuilder<ConsoleBloc, ConsoleState>(
      buildWhen: (previous, current) =>
          previous.envSaving != current.envSaving,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentDim,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(color: AppColors.accentDimBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_outlined,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: AppDimens.gapS),
                Expanded(
                  child: Text(texts.missingKeyTitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textPrimary)),
                ),
              ],
            ),
            if (widget.lookedIn.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(widget.lookedIn,
                    style: AppTextStyles.monospace(10.5,
                        color: AppColors.textMuted)),
              ),
            ],
            const SizedBox(height: AppDimens.gapM),
            // Блок живёт и в узкой колонке карточки change'а: там имя ключа
            // встаёт над полем, иначе от поля остаётся полоска.
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 420;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in widget.keys)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppDimens.gapS),
                        child: narrow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _keyName(key),
                                  const SizedBox(height: 4),
                                  _field(texts, key),
                                ],
                              )
                            : Row(
                                children: [
                                  SizedBox(width: 210, child: _keyName(key)),
                                  const SizedBox(width: AppDimens.gapS),
                                  Expanded(child: _field(texts, key)),
                                ],
                              ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppDimens.gapXs),
            Row(
              children: [
                FilledButton(
                  onPressed: state.envSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(texts.gatePersonalFill,
                      style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: AppDimens.gapM),
                Expanded(
                  child: Text(texts.missingKeyNote,
                      style: AppTextStyles.hint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyName(String key) => Text(key,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          AppTextStyles.monospace(11.5, color: AppColors.textSecondary));

  Widget _field(AppLocalizations texts, String key) {
    final secret = EnvField.isSecretKey(key);
    final obscured = secret && !_revealed.contains(key);
    return TextField(
      controller: _controllers[key],
      obscureText: obscured,
      onSubmitted: (_) => _save(),
      style: AppTextStyles.monospace(12, color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        hintText: texts.envKeyHint(key),
        hintStyle: AppTextStyles.hint,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        suffixIcon: secret
            ? IconButton(
                tooltip: obscured ? texts.envEditShow : texts.envEditHide,
                icon: Icon(obscured ? Icons.visibility : Icons.visibility_off,
                    size: 15, color: AppColors.textMuted),
                onPressed: () => setState(() => obscured
                    ? _revealed.add(key)
                    : _revealed.remove(key)),
              )
            : null,
        border: _border,
        enabledBorder: _border,
      ),
    );
  }

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.controlRadius),
        borderSide: const BorderSide(color: AppColors.border),
      );
}
