import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../models/readable_source.dart';
import '../../../../models/reader_document.dart';
import '../../../../models/reading_progress.dart';
import '../../../../providers/app_providers.dart';
import '../../../../repositories/reading_repository.dart';
import '../../providers/reader_providers.dart';

/// The reading experience. Resolves + downloads + parses a book, then renders it
/// one chapter at a time with `flutter_html`. It restores the last position on
/// open, persists progress as the user reads (debounced + on dispose), and
/// offers font-size, line-height and reading-theme controls. Tapping the page
/// toggles the immersive chrome.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.args});

  final ReaderArgs args;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final ReadingRepository _repo;
  final ScrollController _scrollController = ScrollController();
  final Debouncer _saveDebouncer = Debouncer(delay: const Duration(seconds: 1));

  bool _loading = true;
  Failure? _error;
  ReaderDocument? _doc;
  ReadableSource? _source;
  int _chapterIndex = 0;
  double _restoreFraction = 0;
  bool _chromeVisible = true;

  // External-only availability (e.g. an Internet Archive item we can't render).
  bool _externalOnly = false;
  String? _externalUrl;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(readingRepositoryProvider);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _persist(); // best-effort final save while the controller is still alive
    _saveDebouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _externalOnly = false;
    });
    try {
      final saved = _repo.progressFor(widget.args.id);

      var source = widget.args.source;
      source ??= await _repo.resolveSource(
        title: widget.args.title,
        author: widget.args.author,
        iaIdentifiers: widget.args.iaIdentifiers,
      );

      if (source == null) {
        setState(() {
          _loading = false;
          _error = const Failure(
            'No freely-readable edition was found for this book.',
          );
        });
        return;
      }

      if (!source.isInAppReadable) {
        setState(() {
          _loading = false;
          _source = source;
          _externalOnly = true;
          _externalUrl = source!.onlineReaderUrl;
        });
        return;
      }

      late final ReaderDocument doc;
      try {
        doc = await _repo.loadDocument(
          source,
          title: widget.args.title,
          author: widget.args.author,
        );
      } catch (e) {
        // The download failed (e.g. an Archive file that turned out gated, or a
        // redirect to a login wall). If there's an external reader, degrade to
        // the availability screen rather than showing a hard error.
        if (source.onlineReaderUrl != null) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _source = source;
            _externalOnly = true;
            _externalUrl = source!.onlineReaderUrl;
          });
          return;
        }
        rethrow;
      }

      var chapter = 0;
      var fraction = 0.0;
      if (saved != null && doc.chapterCount > 0) {
        chapter = saved.chapterIndex.clamp(0, doc.chapterCount - 1);
        fraction = saved.scrollFraction.clamp(0.0, 1.0);
      }

      if (!mounted) return;
      setState(() {
        _doc = doc;
        _source = source;
        _chapterIndex = chapter;
        _restoreFraction = fraction;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScroll());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = Failure.from(e);
      });
    }
  }

  void _restoreScroll() {
    if (!_scrollController.hasClients || _restoreFraction <= 0) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo((max * _restoreFraction).clamp(0.0, max));
    _restoreFraction = 0;
  }

  void _onScroll() => _saveDebouncer.run(_persist);

  double get _chapterFraction {
    if (!_scrollController.hasClients) return 0;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scrollController.position.pixels / max).clamp(0.0, 1.0);
  }

  double get _overallPercent {
    final doc = _doc;
    if (doc == null || doc.chapterCount == 0) return 0;
    return ((_chapterIndex + _chapterFraction) / doc.chapterCount)
        .clamp(0.0, 1.0);
  }

  void _persist() {
    final doc = _doc;
    final source = _source;
    if (doc == null || source == null) return;

    _repo.saveProgress(
      ReadingProgress(
        id: widget.args.id,
        title: doc.title.isNotEmpty ? doc.title : widget.args.title,
        author: doc.author.isNotEmpty ? doc.author : widget.args.author,
        coverUrl: widget.args.coverUrl,
        format: source.isEpub
            ? 'epub'
            : (source.isText ? 'text' : 'html'),
        contentUrl: source.url,
        provider: source.provider == SourceProvider.internetArchive
            ? 'internetArchive'
            : 'gutenberg',
        chapterIndex: _chapterIndex,
        scrollFraction: _chapterFraction,
        totalChapters: doc.chapterCount,
        percent: _overallPercent,
      ),
    );
  }

  void _goToChapter(int index) {
    final doc = _doc;
    if (doc == null) return;
    setState(() => _chapterIndex = index.clamp(0, doc.chapterCount - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _persist();
    });
  }

  ({Color bg, Color fg}) _colors(ReaderTheme theme) => switch (theme) {
        ReaderTheme.dark => (bg: const Color(0xFF000000), fg: const Color(0xFFE6E6E6)),
        ReaderTheme.dim => (bg: const Color(0xFF121212), fg: const Color(0xFFCFCFCF)),
        ReaderTheme.sepia => (bg: const Color(0xFFF4ECD8), fg: const Color(0xFF5B4636)),
      };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(child: AppLoadingView(message: 'Preparing your book…')),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(leading: const BackButton()),
        body: AppErrorView(failure: _error!, onRetry: _load),
      );
    }

    if (_externalOnly) {
      return _ExternalAvailabilityView(
        title: widget.args.title,
        url: _externalUrl,
      );
    }

    final doc = _doc!;
    final chapter = doc.chapters[_chapterIndex];
    final colors = _colors(settings.theme);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppConstants.spaceLg,
                  MediaQuery.paddingOf(context).top + 64,
                  AppConstants.spaceLg,
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: AppTextStyles.headline.copyWith(color: colors.fg),
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    Html(
                      data: chapter.html,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(settings.fontSize),
                          lineHeight: LineHeight.number(settings.lineHeight),
                          color: colors.fg,
                        ),
                        'a': Style(color: colors.fg),
                        'img': Style(display: Display.none),
                      },
                    ),
                    const SizedBox(height: AppConstants.spaceXl),
                    _ChapterPager(
                      index: _chapterIndex,
                      total: doc.chapterCount,
                      fg: colors.fg,
                      onPrev: () => _goToChapter(_chapterIndex - 1),
                      onNext: () => _goToChapter(_chapterIndex + 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _TopChrome(
            visible: _chromeVisible,
            title: doc.title,
            onBack: () => context.pop(),
            onChapters: () => _showChapters(doc),
          ),
          _BottomChrome(
            visible: _chromeVisible,
            scrollController: _scrollController,
            chapterIndex: _chapterIndex,
            totalChapters: doc.chapterCount,
            percentOf: (_) => _overallPercent,
            onDecreaseFont: () =>
                ref.read(readerSettingsProvider.notifier).decreaseFont(),
            onIncreaseFont: () =>
                ref.read(readerSettingsProvider.notifier).increaseFont(),
            onSettings: _showSettings,
          ),
        ],
      ),
    );
  }

  Future<void> _showChapters(ReaderDocument doc) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Chapters', style: AppTextStyles.title),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: doc.chapterCount,
                itemBuilder: (context, i) {
                  final selected = i == _chapterIndex;
                  return ListTile(
                    title: Text(
                      doc.chapters[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: selected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.menu_book_rounded,
                            size: 18, color: AppColors.white)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      _goToChapter(i);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _SettingsSheet(),
    );
  }
}

/// Inline chapter navigation at the foot of each chapter.
class _ChapterPager extends StatelessWidget {
  const _ChapterPager({
    required this.index,
    required this.total,
    required this.fg,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final Color fg;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final muted = fg.withValues(alpha: 0.5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: index > 0 ? onPrev : null,
          icon: Icon(Icons.arrow_back_rounded, size: 18, color: index > 0 ? fg : muted),
          label: Text('Previous',
              style: AppTextStyles.label.copyWith(color: index > 0 ? fg : muted)),
        ),
        Text('${index + 1} / $total', style: AppTextStyles.caption.copyWith(color: muted)),
        TextButton.icon(
          onPressed: index < total - 1 ? onNext : null,
          icon: Icon(Icons.arrow_forward_rounded,
              size: 18, color: index < total - 1 ? fg : muted),
          label: Text('Next',
              style: AppTextStyles.label.copyWith(color: index < total - 1 ? fg : muted)),
        ),
      ],
    );
  }
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.visible,
    required this.title,
    required this.onBack,
    required this.onChapters,
  });

  final bool visible;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onChapters;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: visible ? 0 : -120,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          color: AppColors.black.withValues(alpha: 0.92),
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title,
                  ),
                ),
                IconButton(
                  onPressed: onChapters,
                  icon: const Icon(Icons.list_rounded, color: AppColors.white),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.visible,
    required this.scrollController,
    required this.chapterIndex,
    required this.totalChapters,
    required this.percentOf,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
    required this.onSettings,
  });

  final bool visible;
  final ScrollController scrollController;
  final int chapterIndex;
  final int totalChapters;
  final double Function(double) percentOf;
  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: visible ? 0 : -160,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.black,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live progress driven by the scroll controller — only this
                // widget rebuilds while scrolling, never the heavy Html.
                ListenableBuilder(
                  listenable: scrollController,
                  builder: (context, _) {
                    final percent = percentOf(0);
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 3,
                            backgroundColor: AppColors.surfaceHigh,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chapter ${chapterIndex + 1} of $totalChapters  •  ${(percent * 100).round()}%',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: onDecreaseFont,
                      icon: const Icon(Icons.text_decrease_rounded),
                      color: AppColors.white,
                    ),
                    IconButton(
                      onPressed: onIncreaseFont,
                      icon: const Icon(Icons.text_increase_rounded),
                      color: AppColors.white,
                    ),
                    IconButton(
                      onPressed: onSettings,
                      icon: const Icon(Icons.tune_rounded),
                      color: AppColors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reader preferences sheet: line height + reading theme (font size also has
/// quick buttons in the bottom bar). Reads/writes via [readerSettingsProvider].
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display', style: AppTextStyles.title),
            const SizedBox(height: AppConstants.spaceLg),
            Row(
              children: [
                Text('Font size', style: AppTextStyles.body),
                const Spacer(),
                IconButton(
                  onPressed: notifier.decreaseFont,
                  icon: const Icon(Icons.remove_rounded, color: AppColors.white),
                ),
                Text('${settings.fontSize.round()}', style: AppTextStyles.title),
                IconButton(
                  onPressed: notifier.increaseFont,
                  icon: const Icon(Icons.add_rounded, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Row(
              children: [
                Text('Line spacing', style: AppTextStyles.body),
                Expanded(
                  child: Slider(
                    value: settings.lineHeight,
                    min: 1.2,
                    max: 2.2,
                    divisions: 10,
                    activeColor: AppColors.white,
                    inactiveColor: AppColors.surfaceHigh,
                    label: settings.lineHeight.toStringAsFixed(1),
                    onChanged: notifier.setLineHeight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Theme', style: AppTextStyles.body),
            const SizedBox(height: AppConstants.spaceMd),
            Row(
              children: [
                for (final theme in ReaderTheme.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppConstants.spaceMd),
                    child: _ThemeSwatch(
                      theme: theme,
                      selected: settings.theme == theme,
                      onTap: () => notifier.setTheme(theme),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  ({Color bg, Color fg, String label}) get _spec => switch (theme) {
        ReaderTheme.dark => (bg: const Color(0xFF000000), fg: Colors.white, label: 'Dark'),
        ReaderTheme.dim => (bg: const Color(0xFF121212), fg: Colors.white70, label: 'Dim'),
        ReaderTheme.sepia =>
          (bg: const Color(0xFFF4ECD8), fg: const Color(0xFF5B4636), label: 'Sepia'),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: spec.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.white : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text('Aa',
                  style: TextStyle(color: spec.fg, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          Text(spec.label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Shown when the only legal source is an external reader (e.g. some Internet
/// Archive items). We surface availability and let the user copy the link.
class _ExternalAvailabilityView extends StatelessWidget {
  const _ExternalAvailabilityView({required this.title, required this.url});

  final String title;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public_rounded, size: 44, color: AppColors.textTertiary),
              const SizedBox(height: AppConstants.spaceMd),
              Text('Available on Internet Archive',
                  style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.spaceSm),
              Text(
                "This title can't be rendered in-app, but it's legally readable on the Internet Archive.",
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              if (url != null) ...[
                const SizedBox(height: AppConstants.spaceLg),
                SelectableText(url!, style: AppTextStyles.caption, textAlign: TextAlign.center),
                const SizedBox(height: AppConstants.spaceMd),
                FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy link'),
                  style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
