import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/settings_provider.dart';

/// Screen for appearance settings including theme and language selection.
///
/// Allows users to:
/// - Select theme mode (System, Light, Dark)
/// - Select preferred language (English, Deutsch)
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearance)),
      body: ListView(
        children: [
          // Theme section
          _SectionHeader(title: l10n.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _ThemeSelector(
              selectedMode: settings.themeMode,
              onChanged: (mode) {
                ref.read(settingsNotifierProvider.notifier).setThemeMode(mode);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getThemeDescription(settings.themeMode, l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Language section
          _SectionHeader(title: l10n.language),
          _LanguageTile(
            languageCode: settings.language,
            onTap: () => _showLanguageSelector(context, ref, settings.language),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getThemeDescription(AppThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      AppThemeMode.system => l10n.themeDescriptionSystem,
      AppThemeMode.light => l10n.themeDescriptionLight,
      AppThemeMode.dark => l10n.themeDescriptionDark,
    };
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    String currentLanguage,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _LanguageBottomSheet(
        currentLanguage: currentLanguage,
        onSelected: (languageCode) {
          ref.read(settingsNotifierProvider.notifier).setLanguage(languageCode);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Theme selector using SegmentedButton for System/Light/Dark options.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selectedMode, required this.onChanged});

  final AppThemeMode selectedMode;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<AppThemeMode>(
      segments: [
        ButtonSegment(
          value: AppThemeMode.system,
          label: Text(l10n.systemMode),
          icon: const Icon(Icons.brightness_auto),
        ),
        ButtonSegment(
          value: AppThemeMode.light,
          label: Text(l10n.lightMode),
          icon: const Icon(Icons.light_mode),
        ),
        ButtonSegment(
          value: AppThemeMode.dark,
          label: Text(l10n.darkMode),
          icon: const Icon(Icons.dark_mode),
        ),
      ],
      selected: {selectedMode},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onChanged(selection.first);
        }
      },
      showSelectedIcon: false,
    );
  }
}

/// Language tile showing current language with tap to change.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.languageCode, required this.onTap});

  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageName = _getLanguageName(context, languageCode);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(languageName),
      subtitle: Text(_getLanguageNativeName(context, languageCode)),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  String _getLanguageName(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    return switch (code) {
      'en' => l10n.languageEnglish,
      'de' => l10n.languageGerman,
      _ => l10n.languageEnglish,
    };
  }

  String _getLanguageNativeName(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    return switch (code) {
      'en' => l10n.languageEnglishNative,
      'de' => l10n.languageGermanNative,
      _ => l10n.languageEnglishNative,
    };
  }
}

/// Bottom sheet for language selection.
class _LanguageBottomSheet extends StatelessWidget {
  const _LanguageBottomSheet({
    required this.currentLanguage,
    required this.onSelected,
  });

  final String currentLanguage;
  final ValueChanged<String> onSelected;

  static const _languageCodes = ['en', 'de'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final languageNames = {
      'en': (l10n.languageEnglish, l10n.languageEnglishNative),
      'de': (l10n.languageGerman, l10n.languageGermanNative),
    };

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.language, style: theme.textTheme.titleLarge),
          ),
          const Divider(),
          ..._languageCodes.map((code) {
            final isSelected = code == currentLanguage;
            final (name, nativeName) = languageNames[code] ?? (code, code);

            return ListTile(
              leading: isSelected
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : const Icon(Icons.circle_outlined),
              title: Text(name),
              subtitle: Text(nativeName),
              onTap: () => onSelected(code),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
