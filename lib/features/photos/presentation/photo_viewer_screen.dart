// Screen 2 · Fullscreen Photo Viewer — immersive, warm-charcoal (not pure
// black). Top bar shows the uploader; the image supports swipe between photos
// and pinch-zoom; an icon row handles favorite / download / share / delete.
//
// THE single shared viewer for the whole app. It's decoupled from any one
// source: it's handed a [source] key ('all' → the cross-moment All Photos
// collection, otherwise a moment code) + the photo to open first, and resolves
// the live Firestore list itself so favorites/deletes reflect instantly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../auth/data/auth_repository.dart';
import '../../moments/data/mock_photos.dart';
import '../../moments/data/repositories/photos_repository.dart';
import '../../moments/domain/photo.dart';
import '../../moments/presentation/widgets/photo_thumb.dart';

const Color _charcoal = Color(0xFF1C1A17);

String _ago(DateTime t) {
  if (t.millisecondsSinceEpoch <= 0) return '';
  final d = DateTime.now().difference(t);
  if (d.inDays >= 1) return '${d.inDays}d ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
  return 'just now';
}

class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.source,
    required this.initialPhotoId,
  });

  /// 'all' → the All Photos collection; any other value is a moment code. Only
  /// decides what's in the list — the viewing experience is identical.
  final String source;

  /// Id of the photo to open first.
  final String initialPhotoId;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late final PageController _page;
  int _index = 0;
  bool _saving = false;

  List<Photo> _read() => widget.source == 'all'
      ? ref.read(allPhotosProvider)
      : ref.read(momentPhotosProvider(widget.source));

  @override
  void initState() {
    super.initState();
    final start = _read().indexWhere((p) => p.id == widget.initialPhotoId);
    _index = start < 0 ? 0 : start;
    _page = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFavorite(Photo p) async {
    if (p.eventId == null) return;
    HapticFeedback.selectionClick();
    try {
      await ref.read(photosRepositoryProvider).toggleFavorite(
            eventId: p.eventId!,
            photoId: p.id,
            favorite: !p.favorite,
          );
    } catch (_) {
      _toast('Couldn’t update favorite.');
    }
  }

  Future<void> _download(Photo p) async {
    if (_saving) return;
    final url = (p.url != null && p.url!.isNotEmpty) ? p.url! : p.thumbUrl;
    if (url == null || url.isEmpty) {
      _toast('Nothing to save yet.');
      return;
    }
    setState(() => _saving = true);
    _toast('Saving…');
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final res = await ImageGallerySaverPlus.saveImage(
        resp.bodyBytes,
        name: 'gangroll_${p.id}',
        quality: 100,
      );
      final ok = res is Map && (res['isSuccess'] == true);
      _toast(ok ? 'Saved to your gallery' : 'Couldn’t save the photo.');
    } catch (_) {
      _toast('Couldn’t save the photo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Photo p) async {
    final me = ref.read(authStateProvider).value?.uid;
    if (p.eventId == null) {
      _toast('This photo can’t be deleted.');
      return;
    }
    // Firestore rules only allow the uploader to delete — fail kindly otherwise.
    if (me == null || p.uploaderId == null || me != p.uploaderId) {
      _toast('You can only delete photos you added.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cream,
        title: const Text('Delete this photo?'),
        content: const Text(
            'It’s removed for everyone in the moment. This can’t be undone.'),
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
    try {
      await ref.read(photosRepositoryProvider).deletePhoto(
            eventId: p.eventId!,
            photoId: p.id,
          );
      _toast('Photo deleted.');
    } catch (_) {
      _toast('Couldn’t delete the photo.');
    }
  }

  Future<void> _shareCurrent(Photo p) async {
    HapticFeedback.selectionClick();
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${p.uploader} captured this moment on gang.roll — https://gang.roll/p/${p.id}',
        subject: 'A moment from gang.roll',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.source == 'all'
        ? ref.watch(allPhotosProvider)
        : ref.watch(momentPhotosProvider(widget.source));

    if (photos.isEmpty) {
      // Last photo deleted (or nothing to show) → leave the viewer.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(
          backgroundColor: _charcoal, body: SizedBox.shrink());
    }

    // Keep the index (and the controller) in range as the list shrinks.
    if (_index > photos.length - 1) {
      _index = photos.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page.hasClients) _page.jumpToPage(_index);
      });
    }

    final current = photos[_index];
    final myUid = ref.watch(authStateProvider).value?.uid;
    final canDelete = current.uploaderId != null && current.uploaderId == myUid;
    final favCount = photos.where((p) => p.favorite).length;

    return Scaffold(
      backgroundColor: _charcoal,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(photo: current, onClose: () => context.pop()),
            Expanded(
              child: PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: photos.length,
                itemBuilder: (_, i) {
                  final p = photos[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 0.82,
                            child: PhotoThumb(
                                id: p.id, url: p.url ?? p.thumbUrl),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _BottomActions(
              favorite: current.favorite,
              favoriteCount: favCount,
              canDelete: canDelete,
              saving: _saving,
              onFavorite: () => _toggleFavorite(current),
              onShare: () => _shareCurrent(current),
              onDownload: () => _download(current),
              onDelete: () => _delete(current),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.photo, required this.onClose});

  final Photo photo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ago = _ago(photo.uploadedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          GangAvatar(name: photo.uploader, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.uploader,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                if (ago.isNotEmpty)
                  Text(
                    ago,
                    style: AppText.mono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.favorite,
    required this.favoriteCount,
    required this.canDelete,
    required this.saving,
    required this.onFavorite,
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  final bool favorite;
  final int favoriteCount;
  final bool canDelete;
  final bool saving;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Action(
            icon: favorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: favorite ? AppTheme.coral : Colors.white,
            label: '$favoriteCount',
            onTap: onFavorite,
          ),
          _Action(
            icon: saving ? Icons.hourglass_top_rounded : Icons.download_rounded,
            onTap: onDownload,
          ),
          _Action(icon: Icons.ios_share_rounded, onTap: onShare),
          _Action(
            icon: Icons.delete_outline_rounded,
            color: canDelete
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!,
                style: AppText.mono(
                    fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
          ],
        ],
      ),
    );
  }
}
