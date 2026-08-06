import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/package_info_providers.dart';
import '../../../../app/theme_settings.dart';

/// 設定對話框：切換主題、顯示版本資訊。
Future<void> showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final preference in ThemePreference.values)
              RadioListTile<ThemePreference>(
                value: preference,
                groupValue: current,
                title: Text(preference.label),
                onChanged: (value) {
                  if (value != null) {
                    notifier.set(value);
                  }
                },
              ),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Version',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: const _VersionText(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _VersionText extends ConsumerWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(packageInfoProvider);

    return asyncInfo.when(
      loading: () => const Text('—'),
      error: (_, __) => const Text('—'),
      data: (info) => Text('${info.version} (build ${info.buildNumber})'),
    );
  }
}
