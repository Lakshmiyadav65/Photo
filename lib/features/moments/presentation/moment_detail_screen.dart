// Screen 1 · Moment Gallery — the primary moment detail screen: editorial
// header, social member row, filter tabs, and a responsive photo grid, with a
// coral upload FAB. Insights & members open as bottom sheets; settings pushes a
// screen. Mock photos for now (Phase 5 streams events/<code>/photos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../quick_shoot/data/models/pending_photo.dart';
import '../../quick_shoot/data/providers/photo_queue_provider.dart';
import '../../quick_shoot/presentation/widgets/pending_photo_tile.dart';
import '../../quick_shoot/presentation/widgets/upload_progress_banner.dart';
import '../../upload/presentation/upload_actions.dart';
import '../data/mock_moments.dart';
import '../data/mock_photos.dart';
import '../domain/moment.dart';
import '../domain/photo.dart';
import 'widgets/avatar_stack.dart';
import 'widgets/insights_view.dart';
import 'widgets/members_view.dart';
import 'widgets/photo_thumb.dart';

const _kCurrentUser = 'Aarav';

enum _Filter { all, byYou, favorites }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.byYou => 'By you',
        _Filter.favorites => 'Favorites',
      };
}

class MomentDetailScreen extends ConsumerStatefulWidget {
  const MomentDetailScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen> {
  _Filter _filter = _Filter.all;

  List<Photo> _applyFilter(List<Photo> photos) => switch (_filter) {
        _Filter.all => photos,
        _Filter.byYou =>
          photos.where((p) => p.uploader == _kCurrentUser).toList(),
        _Filter.favorites => photos.where((p) => p.favorite).toList(),
      };

  void _openPhoto(Photo p) =>
      context.push('/photos/${widget.code}/${p.id}');

  void _photoActions(Photo p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cream,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final (icon, label) in const [
              (Icons.favorite_border_rounded, 'Favorite'),
              (Icons.download_rounded, 'Download'),
              (Icons.ios_share_rounded, 'Share'),
            ])
              ListTile(
                leading: Icon(icon, color: AppTheme.ink),
                title: Text(label,
                    style: Theme.of(context).textTheme.titleMedium),
                onTap: () => Navigator.of(context).pop(),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(momentByCodeProvider(widget.code));
    if (moment == null) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(),
        body: Center(
          child: Text('We couldn’t find that moment.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    final photos = ref.watch(momentPhotosProvider(widget.code));
    final filtered = _applyFilter(photos);
    // Quick Shoot local photos (pending → uploaded). Hidden under Favorites.
    final localPhotos = _filter == _Filter.favorites
        ? const <PendingPhoto>[]
        : (ref.watch(localPhotosProvider(widget.code)).value ??
            const <PendingPhoto>[]);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      floatingActionButton: _UploadFab(
        onTap: () => pickFromGallery(context, ref,
            momentCode: moment.code, fromMoment: true),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _GalleryHeader(
              moment: moment,
              onBack: () => context.pop(),
              onInsights: () => showInsightsSheet(context, moment, photos),
              onShare: () => context.push('/moment/${moment.code}/share'),
              // The moment ⋮ opens THIS moment's settings only — gang-level
              // leave/delete live on the gang screen, never here.
              onMore: () => context.push('/moment/${moment.code}/settings'),
            ),
            _MemberRow(
              moment: moment,
              onTap: () => showMembersSheet(
                context,
                moment,
                photos,
                onInvite: () => context.push('/moment/${moment.code}/share'),
              ),
            ),
            _FilterTabs(
              value: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            // Quick Shoot photos waiting to upload to this moment. Renders
            // nothing when the queue is empty. Tapping through opens the
            // dedicated pending view with the grey-overlay grid.
            GestureDetector(
              onTap: () => context.push('/pending/${moment.code}'),
              child: UploadProgressBanner(momentId: moment.code),
            ),
            Expanded(
              child: (filtered.isEmpty && localPhotos.isEmpty)
                  ? _EmptyFilter(filter: _filter)
                  : _PhotoGrid(
                      localPhotos: localPhotos,
                      photos: filtered,
                      onTap: _openPhoto,
                      onLongPress: _photoActions,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.moment,
    required this.onBack,
    required this.onInsights,
    required this.onShare,
    required this.onMore,
  });

  final Moment moment;
  final VoidCallback onBack;
  final VoidCallback onInsights;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(fontSize: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  '${moment.photoCount} SHOTS · ${moment.memberCount} MEMBERS',
                  style: AppText.label(fontSize: 9.5),
                ),
              ],
            ),
          ),
          _HeaderIcon(icon: Icons.bar_chart_rounded, onTap: onInsights),
          _HeaderIcon(icon: Icons.ios_share_rounded, onTap: onShare),
          _HeaderIcon(icon: Icons.more_horiz_rounded, onTap: onMore),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: AppTheme.ink,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.moment, required this.onTap});

  final Moment moment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 14),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AvatarStack(names: moment.members, size: 30, max: 5),
              ),
            ),
          ),
          _AddButton(onTap: onTap),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.paper,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: AppTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 16, color: AppTheme.ink),
                const SizedBox(width: 5),
                Text('ADD', style: AppText.label(fontSize: 10, color: AppTheme.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          for (final f in _Filter.values) ...[
            _Tab(
              label: f.label,
              active: f == value,
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: 22),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: active ? AppTheme.ink : AppTheme.muted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              width: 18,
              decoration: BoxDecoration(
                color: active ? AppTheme.coral : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.localPhotos,
    required this.photos,
    required this.onTap,
    required this.onLongPress,
  });

  /// Quick Shoot local photos (newest first) — rendered first, greyed while
  /// pending and full colour once uploaded.
  final List<PendingPhoto> localPhotos;
  final List<Photo> photos;
  final ValueChanged<Photo> onTap;
  final ValueChanged<Photo> onLongPress;

  @override
  Widget build(BuildContext context) {
    final localCount = localPhotos.length;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: localCount + photos.length,
      itemBuilder: (_, i) {
        if (i < localCount) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PendingPhotoTile(photo: localPhotos[i]),
          );
        }
        final p = photos[i - localCount];
        return GestureDetector(
          onTap: () => onTap(p),
          onLongPress: () => onLongPress(p),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoThumb(id: p.id, url: p.thumbUrl ?? p.url),
                if (p.favorite)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.favorite_rounded,
                        size: 14, color: Colors.white),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final msg = switch (filter) {
      _Filter.byYou => 'You haven’t added a shot yet.',
      _Filter.favorites => 'No favorites yet.',
      _ => 'No photos yet.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _UploadFab extends StatelessWidget {
  const _UploadFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: AppTheme.softShadow, blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Material(
        color: AppTheme.coral,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
