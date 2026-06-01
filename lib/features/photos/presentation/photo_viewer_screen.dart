// Screen 2 · Fullscreen Photo Viewer — immersive, warm-charcoal (not pure
// black). Top bar shows the uploader; the image supports swipe between photos
// and pinch-zoom; a minimal icon row handles favorite/download/share/more.
//
// THE single shared viewer for the whole app. It's deliberately decoupled from
// any one source: callers hand it a photo collection + the photo to open, and
// the experience is identical whether that list came from a moment, All Photos,
// favorites, search, or a gang. Only the contents of [photos] differ.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../moments/domain/photo.dart';
import '../../moments/presentation/widgets/photo_thumb.dart';

const Color _charcoal = Color(0xFF1C1A17);

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inDays >= 1) return '${d.inDays}d ago';
  if (d.inHours >= 1) return '${d.inHours}h ago';
  if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
  return 'just now';
}

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialPhotoId,
  });

  /// The collection to page through. The source (a moment, All Photos,
  /// favorites, search results, a gang, …) only decides what's in this list —
  /// the viewing experience itself is identical everywhere.
  final List<Photo> photos;

  /// Id of the photo to open first.
  final String initialPhotoId;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final List<Photo> _photos;
  late final PageController _page;
  late int _index;
  final _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _photos = widget.photos;
    final start = _photos.indexWhere((p) => p.id == widget.initialPhotoId);
    _index = start < 0 ? 0 : start;
    _page = PageController(initialPage: _index);
    for (final p in _photos) {
      if (p.favorite) _favorites.add(p.id);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Hands the OS its native share sheet (WhatsApp, Instagram, Drive, …). The
  /// real impl will attach the photo file; for the frontend mock we share a
  /// descriptive text + a permalink shape so the flow is end-to-end.
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
    if (_photos.isEmpty) {
      return const Scaffold(backgroundColor: _charcoal, body: SizedBox.shrink());
    }
    final current = _photos[_index];
    final isFav = _favorites.contains(current.id);

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
                itemCount: _photos.length,
                itemBuilder: (_, i) {
                  final p = _photos[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 0.82,
                            child: PhotoThumb(id: p.id),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _BottomActions(
              favorite: isFav,
              favoriteCount: _favorites.length,
              onFavorite: () {
                HapticFeedback.selectionClick();
                setState(() {
                  isFav ? _favorites.remove(current.id) : _favorites.add(current.id);
                });
              },
              onShare: () => _shareCurrent(current),
              onDownload: () => _toast('Download coming soon'),
              onMore: () => _toast('More options coming soon'),
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
                Text(
                  _ago(photo.uploadedAt),
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
    required this.onFavorite,
    required this.onShare,
    required this.onDownload,
    required this.onMore,
  });

  final bool favorite;
  final int favoriteCount;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Action(
            icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: favorite ? AppTheme.coral : Colors.white,
            label: '$favoriteCount',
            onTap: onFavorite,
          ),
          _Action(icon: Icons.download_rounded, onTap: onDownload),
          _Action(icon: Icons.ios_share_rounded, onTap: onShare),
          _Action(icon: Icons.more_horiz_rounded, onTap: onMore),
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
