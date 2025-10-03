import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filter_provider.dart';
import '../utils/constants.dart';

/// 검색 및 필터 바
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterProvider>(
      builder: (context, filterProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          color: Colors.grey[50],
          child: Column(
            children: [
              // 검색 바
              TextField(
                decoration: InputDecoration(
                  hintText: '식품 검색...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filterProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            filterProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  filterProvider.setSearchQuery(value);
                },
              ),
              
              const SizedBox(height: 12),
              
              // 필터 칩 행
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 카테고리 필터
                    _buildFilterChip(
                      context,
                      label: '카테고리',
                      icon: Icons.category,
                      isSelected: filterProvider.selectedCategory != null,
                      onTap: () => _showCategoryFilter(context, filterProvider),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 정렬 옵션
                    _buildFilterChip(
                      context,
                      label: filterProvider.sortOption.label,
                      icon: filterProvider.sortOption.icon,
                      isSelected: true,
                      onTap: () => _showSortOptions(context, filterProvider),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 필터 초기화
                    if (filterProvider.hasActiveFilters) ...[
                      _buildFilterChip(
                        context,
                        label: '초기화',
                        icon: Icons.clear_all,
                        isSelected: false,
                        onTap: () {
                          filterProvider.clearFilters();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 필터 칩 위젯
  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.freshGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppConstants.freshGreen
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카테고리 필터 다이얼로그
  Future<void> _showCategoryFilter(
    BuildContext context,
    FilterProvider filterProvider,
  ) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 전체 보기
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('전체'),
                selected: filterProvider.selectedCategory == null,
                onTap: () => Navigator.pop(context, 'all'),
              ),
              const Divider(),
              // 카테고리 목록
              ...FoodCategories.all.map((category) {
                return ListTile(
                  leading: Text(
                    FoodCategories.icons[category] ?? '📦',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(category),
                  selected: filterProvider.selectedCategory == category,
                  onTap: () => Navigator.pop(context, category),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      if (selected == 'all') {
        filterProvider.setCategory(null);
      } else {
        filterProvider.setCategory(selected);
      }
    }
  }

  /// 정렬 옵션 다이얼로그
  Future<void> _showSortOptions(
    BuildContext context,
    FilterProvider filterProvider,
  ) async {
    final selected = await showDialog<SortOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정렬 기준'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values.map((option) {
            return ListTile(
              leading: Icon(option.icon),
              title: Text(option.label),
              selected: filterProvider.sortOption == option,
              onTap: () => Navigator.pop(context, option),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      filterProvider.setSortOption(selected);
    }
  }
}

