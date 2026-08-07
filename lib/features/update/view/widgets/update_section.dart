import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/update_state.dart';
import '../../viewmodel/update_providers.dart';

/// Release 頁面；下載失敗或平台沒有安裝檔時的後備出口。
const releasesPageUrl = 'https://github.com/swarfte/sci-calc/releases/latest';

/// 設定對話框中的「軟體更新」區塊。
///
/// 不會自己觸發檢查——背景檢查由 `UpdateCheckStarter` 負責，這裡只呈現
/// `UpdateController` 的狀態，並提供手動重新檢查與下載的入口。
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final isSupported = ref.watch(updateSupportedProvider);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Update', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (!isSupported)
          const _UnsupportedPlatformBody()
        else
          _CheckBody(state: state),
      ],
    );
  }
}

/// Linux / iOS / Web：CI 沒有產出安裝檔，只提供 Release 頁面連結。
class _UnsupportedPlatformBody extends StatelessWidget {
  const _UnsupportedPlatformBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic updates are not available on this platform.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        const _ReleasePageButton(),
      ],
    );
  }
}

class _CheckBody extends ConsumerWidget {
  const _CheckBody({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(updateControllerProvider.notifier);

    switch (state.checkPhase) {
      case UpdateCheckPhase.idle:
        return Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => controller.checkForUpdates(),
            icon: const Icon(Icons.system_update_alt, size: 18),
            label: const Text('Check for updates'),
          ),
        );

      case UpdateCheckPhase.checking:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Checking for updates…', style: theme.textTheme.bodySmall),
          ],
        );

      case UpdateCheckPhase.upToDate:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "You're on the latest version",
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => controller.checkForUpdates(),
              child: const Text('Check again'),
            ),
          ],
        );

      case UpdateCheckPhase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.checkError ?? 'Could not check for updates',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => controller.checkForUpdates(),
                  child: const Text('Retry'),
                ),
                const _ReleasePageButton(),
              ],
            ),
          ],
        );

      case UpdateCheckPhase.updateAvailable:
        return _UpdateAvailableBody(state: state);
    }
  }
}

class _UpdateAvailableBody extends ConsumerWidget {
  const _UpdateAvailableBody({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final release = state.latestRelease;
    final asset = state.asset;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.new_releases_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                release == null
                    ? 'An update is available'
                    : 'Update available: ${release.version.display}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (asset != null) ...[
          const SizedBox(height: 2),
          Text(
            [asset.name, asset.humanSize].nonNulls.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        if (asset == null)
          // 有新版本，但這個 Release 沒有對應這個平台的安裝檔。
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                release == null
                    ? 'Open Settings again after the check completes, or download it from GitHub.'
                    : 'No installer for this platform in that release.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              const _ReleasePageButton(),
            ],
          )
        else
          _DownloadBody(state: state),
      ],
    );
  }
}

class _DownloadBody extends ConsumerWidget {
  const _DownloadBody({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(updateControllerProvider.notifier);
    final platform = ref.watch(updatePlatformProvider);

    switch (state.downloadPhase) {
      case UpdateDownloadPhase.idle:
        return Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: controller.downloadAndInstall,
            icon: const Icon(Icons.download, size: 18),
            label: Text(platform.installActionLabel),
          ),
        );

      case UpdateDownloadPhase.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: LinearProgressIndicator(value: state.progress),
            ),
            const SizedBox(height: 6),
            Text(state.progressLabel, style: theme.textTheme.bodySmall),
          ],
        );

      case UpdateDownloadPhase.opening:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Opening the installer…',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        );

      case UpdateDownloadPhase.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Downloaded — follow the installer to finish.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (state.downloadedPath != null) _DownloadedPathText(state: state),
          ],
        );

      case UpdateDownloadPhase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.downloadError ?? 'Download failed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            // 檔案已經下載完、只是開啟失敗時，讓使用者知道檔案在哪，並可只重試
            // 「開啟」而不必重新下載。
            if (state.downloadedPath != null) _DownloadedPathText(state: state),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                if (state.downloadedPath != null)
                  TextButton(
                    onPressed: controller.retryOpenDownloadedFile,
                    child: const Text('Open installer'),
                  )
                else
                  TextButton(
                    onPressed: controller.downloadAndInstall,
                    child: const Text('Retry'),
                  ),
                const _ReleasePageButton(),
              ],
            ),
          ],
        );
    }
  }
}

class _DownloadedPathText extends StatelessWidget {
  const _DownloadedPathText({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SelectableText(
        state.downloadedPath!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// 在瀏覽器開啟 GitHub Release 頁面。
///
/// 已經取得 Release 時用它自己的 `html_url`（會直接指向那一版），否則退回
/// `releases/latest`。
class _ReleasePageButton extends ConsumerWidget {
  const _ReleasePageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final htmlUrl = ref.watch(updateControllerProvider).latestRelease?.htmlUrl;
    final url = (htmlUrl == null || htmlUrl.isEmpty)
        ? releasesPageUrl
        : htmlUrl;

    return TextButton(
      onPressed: () async {
        // 開不起來也不該讓設定對話框崩掉；這本來就只是後備選項。
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } on Object {
          // 忽略：使用者仍可手動前往 GitHub。
        }
      },
      child: const Text('Open release page'),
    );
  }
}
