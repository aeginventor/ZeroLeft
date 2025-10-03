import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// 즐겨찾기 그리드 위젯
class FavoriteGrid extends StatefulWidget {
  final ValueChanged<FavoriteItem>? onFavoriteSelected;

  const FavoriteGrid({
    super.key,
    this.onFavoriteSelected,
  });

  @override
  State<FavoriteGrid> createState() => _FavoriteGridState();
}

class _FavoriteGridState extends State<FavoriteGrid> {
  final DatabaseService _db = DatabaseService.instance;
  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _db.getAllFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(
              Icons.star_border,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '즐겨찾기가 비어있어요',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '자주 쓰는 식품을 즐겨찾기에 추가해보세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _FavoriteCard(
          favorite: favorite,
          onTap: () {
            if (widget.onFavoriteSelected != null) {
              widget.onFavoriteSelected!(favorite);
            }
          },
          onLongPress: () => _showRemoveDialog(favorite),
        );
      },
    );
  }

  /// 즐겨찾기 제거 다이얼로그
  Future<void> _showRemoveDialog(FavoriteItem favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('즐겨찾기 제거'),
        content: Text('${favorite.name}을(를) 즐겨찾기에서 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제거'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.removeFavorite(favorite.name);
      await _loadFavorites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${favorite.name}을(를) 즐겨찾기에서 제거했습니다'),
          ),
        );
      }
    }
  }
}

/// 즐겨찾기 카드 위젯
class _FavoriteCard extends StatelessWidget {
  final FavoriteItem favorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _FavoriteCard({
    required this.favorite,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final icon = favorite.category != null
        ? FoodCategories.icons[favorite.category]
        : null;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              if (icon != null) ...[
                Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
              ],
              
              // 이름
              Text(
                favorite.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 즐겨찾기 별
              const SizedBox(height: 2),
              const Icon(
                Icons.star,
                color: AppConstants.warningYellow,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 즐겨찾기 추가 버튼
class AddToFavoriteButton extends StatelessWidget {
  final String foodName;
  final String? category;
  final int? defaultShelfLife;

  const AddToFavoriteButton({
    super.key,
    required this.foodName,
    this.category,
    this.defaultShelfLife,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: DatabaseService.instance.isFavorite(foodName),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? AppConstants.warningYellow : Colors.grey,
          ),
          onPressed: () async {
            if (isFavorite) {
              // 즐겨찾기 제거
              await DatabaseService.instance.removeFavorite(foodName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$foodName을(를) 즐겨찾기에서 제거했습니다'),
                  ),
                );
              }
            } else {
              // 즐겨찾기 추가
              final favorite = FavoriteItem(
                name: foodName,
                category: category,
                defaultShelfLife: defaultShelfLife,
              );
              await DatabaseService.instance.addFavorite(favorite);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$foodName을(를) 즐겨찾기에 추가했습니다'),
                    backgroundColor: AppConstants.freshGreen,
                  ),
                );
              }
            }
          },
          tooltip: isFavorite ? '즐겨찾기 제거' : '즐겨찾기 추가',
        );
      },
    );
  }
}

