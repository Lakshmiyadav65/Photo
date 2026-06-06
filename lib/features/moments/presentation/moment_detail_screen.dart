// Screen 1 · Moment Gallery — the primary moment detail screen: editorial
// header, social member row, filter tabs, and a responsive photo grid, with a
// coral upload FAB. Insights & members open as bottom sheets; settings pushes a
// screen. Mock photos for now (Phase 5 streams events/<code>/photos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../app/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../quick_shoot/data/models/pending_photo.dart';
import '../../quick_shoot/data/providers/photo_queue_provider.dart';
import '../../quick_shoot/presentation/widgets/pending_photo_tile.dart';
import '../../quick_shoot/presentation/widgets/upload_progress_banner.dart';
import '../../upload/presentation/upload_actions.dart';
import '../data/mock_moments.dart';
import '../data/mock_photos.dart';
import '../data/repositories/photos_repository.dart';
import '../domain/moment.dart';
import '../domain/photo.dart';
import 'widgets/avatar_stack.dart';
import 'widgets/insights_view.dart';
import 'widgets/members_view.dart';
import 'widgets/photo_thumb.dart';

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

  /// Ids of selected (Firestore) photos — non-empty puts the grid in
  /// multi-select mode. Pending local tiles aren't selectable (not shared yet).
  final Set<String> _selected = {};
  bool _bulkBusy = false;

  List<Photo> _applyFilter(List<Photo> photos) {
    final myUid = ref.read(authStateProvider).value?.uid;
    return switch (_filter) {
      _Filter.all => photos,
      _Filter.byYou =>
        photos.where((p) => p.uploaderId != null && p.uploaderId == myUid)
            .toList(),
      _Filter.favorites => photos.where((p) => p.favorite).toList(),
    };
  }

  void _openPhoto(Photo p) => context.push('/photos/${widget.code}/${p.id}');

  void _onPhotoTap(Photo p) {
    if (_selected.isNotEmpty) {
      _toggleSelected(p.id);
    } else {
      _openPhoto(p);
    }
  }

  void _toggleSelected(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  void _clearSelection() => setState(_selected.clear);

  /// Save every selected photo to the device gallery (fetch bytes → MediaStore).
  Future<void> _saveSelected() async {
    final selected = ref
        .read(momentPhotosProvider(widget.code))
        .where((p) => _selected.contains(p.id))
        .toList();
    setState(() => _bulkBusy = true);
    var ok = 0;
    for (final p in selected) {
      final url = (p.url != null && p.url!.isNotEmpty) ? p.url! : p.thumbUrl;
      if (url == null || url.isEmpty) continue;
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode != 200) continue;
        final res = await ImageGallerySaverPlus.saveImage(
          resp.bodyBytes,
          name: 'gangroll_${p.id}',
          quality: 100,
        );
        if (res is Map && res['isSuccess'] == true) ok++;
      } catch (_) {
        // Skip the one that failed; keep saving the rest.
      }
    }
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selected.clear();
    });
    _snack(ok == 0
        ? 'Couldn’t save those photos.'
        : 'Saved $ok photo${ok == 1 ? '' : 's'} to your gallery');
  }

  /// Delete selected photos you uploaded (rules block deleting others'). Photos
  /// that aren't yours are skipped and reported.
  Future<void> _deleteSelected() async {
    final myUid = ref.read(authStateProvider).value?.uid;
    final selected = ref
        .read(momentPhotosProvider(widget.code))
        .where((p) => _selected.contains(p.id))
        .toList();
    final mine = selected
        .where((p) =>
            p.eventId != null && p.uploaderId != null && p.uploaderId == myUid)
        .toList();
    final skipped = selected.length - mine.length;
    if (mine.isEmpty) {
      _snack('You can only delete photos you added.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cream,
        title: Text('Delete ${mine.length} '
            'photo${mine.length == 1 ? '' : 's'}?'),
        content: const Text(
            'They’re removed for everyone in the moment. This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.coral)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _bulkBusy = true);
    final repo = ref.read(photosRepositoryProvider);
    var ok = 0;
    for (final p in mine) {
      try {
        await repo.deletePhoto(eventId: p.eventId!, photoId: p.id);
        ok++;
      } catch (_) {
        // Continue with the rest.
      }
    }
    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selected.clear();
    });
    _snack(skipped > 0
        ? 'Deleted $ok · skipped $skipped not yours'
        : 'Deleted $ok photo${ok == 1 ? '' : 's'}');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    // Quick Shoot local tiles — only shots still in flight (pending /
    // uploading / failed). Once a shot finishes it's written to Firestore and
    // renders from there via [photos], so we drop the uploaded local row to
    // avoid showing the same photo twice. Hidden entirely under Favorites.
    final localPhotos = _filter == _Filter.favorites
        ? const <PendingPhoto>[]
        : (ref.watch(localPhotosProvider(widget.code)).value ??
                const <PendingPhoto>[])
            .where((p) => p.isOutstanding)
            .toList();

    final selecting = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      // The upload FAB steps aside while multi-selecting.
      floatingActionButton: selecting
          ? null
          : _UploadFab(
              onTap: () => pickFromGallery(context, ref,
                  momentCode: moment.code, fromMoment: true),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header swaps for a selection action bar while picking photos.
            if (selecting)
              _SelectionBar(
                count: _selected.length,
                busy: _bulkBusy,
                onClose: _clearSelection,
                onSave: _bulkBusy ? null : _saveSelected,
                onDelete: _bulkBusy ? null : _deleteSelected,
              )
            else
              _GalleryHeader(
                moment: moment,
                onBack: () => context.pop(),
                onInsights: () => showInsightsSheet(context, moment, photos),
                onShare: () => context.push('/moment/${moment.code}/share'),
                // The moment ⋮ opens THIS moment's settings only — gang-level
                // leave/delete live on the gang screen, never here.
                onMore: () => context.push('/moment/${moment.code}/settings'),
              ),
            if (!selecting) ...[
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
            ],
            Expanded(
              child: (filtered.isEmpty && localPhotos.isEmpty)
                  ? _EmptyFilter(filter: _filter)
                  : _PhotoGrid(
                      localPhotos: localPhotos,
                      photos: filtered,
                      selectedIds: _selected,
                      onTap: _onPhotoTap,
                      onLongPress: (p) => _toggleSelected(p.id),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contextual top bar shown while multi-selecting: count + bulk Save / Delete.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.busy,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
  });

  final int count;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: busy ? null : onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Text(
              '$count selected',
              style: AppText.display(fontSize: 19),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.coral),
              ),
            )
          else ...[
            _HeaderIcon(icon: Icons.download_rounded, onTap: onSave ?? () {}),
            _HeaderIcon(
                icon: Icons.delete_outline_rounded, onTap: onDelete ?? () {}),
          ],
        ],
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
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
  });

  /// Quick Shoot local photos (newest first) — rendered first, greyed while
  /// pending and full colour once uploaded.
  final List<PendingPhoto> localPhotos;
  final List<Photo> photos;

  /// Ids of selected photos — drives the multi-select check overlay.
  final Set<String> selectedIds;
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
        final selected = selectedIds.contains(p.id);
        return GestureDetector(
          onTap: () => onTap(p),
          onLongPress: () => onLongPress(p),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoThumb(id: p.id, url: p.thumbUrl ?? p.url),
                if (p.favorite && !selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.favorite_rounded,
                        size: 14, color: Colors.white),
                  ),
                if (selected) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.coral.withValues(alpha: 0.28),
                      border: Border.all(color: AppTheme.coral, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle_rounded,
                        size: 20, color: AppTheme.coral),
                  ),
                ],
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
