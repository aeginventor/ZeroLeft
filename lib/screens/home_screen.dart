import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/animated_food_list.dart';
import '../widgets/search_filter_bar.dart';
import '../utils/constants.dart';
import 'add_food_screen.dart';
import 'settings_screen.dart';
import 'food_detail_screen.dart';

/// 홈 화면 (메인 화면)
/// 
/// "신선하게 보관중" / "소비 완료!" 두 개의 탭으로 구성
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadFoods();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        // 검색 바 숨길 때 필터 초기화
        context.read<FilterProvider>().clearFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appNameKorean,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${AppConstants.appName})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 검색 버튼
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: _toggleSearchBar,
            tooltip: '검색',
          ),
          
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: AppConstants.settings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppConstants.tabRemainingFood),
            Tab(text: AppConstants.tabConsumedFood),
          ],
        ),
      ),
      body: Column(
        children: [
          // 검색 및 필터 바
          if (_showSearchBar)
            AnimatedContainer(
              duration: AppConstants.normalAnimation,
              curve: Curves.easeInOut,
              child: const SearchFilterBar(),
            ),
          
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 탭 1: 신선하게 보관중 (남은 음식)
                _RemainingFoodList(showSearchBar: _showSearchBar),
                // 탭 2: 소비 완료! (먹은 음식)
                _ConsumedFoodList(showSearchBar: _showSearchBar),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 식품 추가 화면으로 이동
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFoodScreen(),
            ),
          );
          
          // 추가 성공 시 리스트 새로고침
          if (result == true && mounted) {
            context.read<FoodProvider>().loadFoods();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(AppConstants.addFoodButton),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// 남은 음식 리스트 (보관 중)
class _RemainingFoodList extends StatelessWidget {
  final bool showSearchBar;
  
  const _RemainingFoodList({required this.showSearchBar});
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, FilterProvider>(
      builder: (context, foodProvider, filterProvider, child) {
        final allRemainingFoods = foodProvider.remainingFoods;
        final remainingFoods = showSearchBar
            ? filterProvider.applyFilters(allRemainingFoods)
            : allRemainingFoods;

        // 로딩 중
        if (foodProvider.isLoading) {
          return const AnimatedLoadingIndicator(
            message: '식품 목록을 불러오는 중...',
          );
        }

        // 빈 상태
        if (remainingFoods.isEmpty) {
          final message = showSearchBar && filterProvider.hasActiveFilters
              ? '검색 결과가 없습니다'
              : AppConstants.emptyRemainingFood;
          
          return AnimatedEmptyState(
            icon: Icons.shopping_basket_outlined,
            message: message,
            subtitle: showSearchBar && filterProvider.hasActiveFilters
                ? '다른 검색어나 필터를 시도해보세요'
                : null,
          );
        }

        // 리스트 표시
        return RefreshIndicator(
          onRefresh: () => foodProvider.loadFoods(),
          child: AnimatedFoodList(
            foods: remainingFoods,
            isConsumed: false,
            onTap: (food) async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailScreen(food: food),
                ),
              );
              
              if (result == true && context.mounted) {
                await foodProvider.loadFoods();
              }
            },
            onCheckChanged: (food, value) async {
              if (value == true) {
                await foodProvider.markAsConsumed(food.id);
              }
            },
            onDelete: (food) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(AppConstants.deleteConfirmTitle),
                  content: Text('${food.name}을(를) ${AppConstants.deleteConfirmMessage}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await foodProvider.deleteFood(food.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppConstants.deleteSuccess),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}

/// 소비 완료 음식 리스트
class _ConsumedFoodList extends StatelessWidget {
  final bool showSearchBar;
  
  const _ConsumedFoodList({required this.showSearchBar});
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, FilterProvider>(
      builder: (context, foodProvider, filterProvider, child) {
        final allConsumedFoods = foodProvider.consumedFoods;
        final consumedFoods = showSearchBar
            ? filterProvider.applyFilters(allConsumedFoods)
            : allConsumedFoods;

        // 로딩 중
        if (foodProvider.isLoading) {
          return const AnimatedLoadingIndicator();
        }

        // 빈 상태
        if (consumedFoods.isEmpty) {
          final message = showSearchBar && filterProvider.hasActiveFilters
              ? '검색 결과가 없습니다'
              : AppConstants.emptyConsumedFood;
          
          return AnimatedEmptyState(
            icon: Icons.check_circle_outline,
            message: message,
            subtitle: showSearchBar && filterProvider.hasActiveFilters
                ? '다른 검색어나 필터를 시도해보세요'
                : null,
          );
        }

        // 리스트 표시
        return RefreshIndicator(
          onRefresh: () => foodProvider.loadFoods(),
          child: AnimatedFoodList(
            foods: consumedFoods,
            isConsumed: true,
            onTap: (food) async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailScreen(food: food),
                ),
              );
              
              if (result == true && context.mounted) {
                await foodProvider.loadFoods();
              }
            },
            onCheckChanged: (food, value) async {
              if (value == false) {
                await foodProvider.markAsUnconsumed(food.id);
              }
            },
            onDelete: (food) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(AppConstants.deleteConfirmTitle),
                  content: Text('${food.name}을(를) ${AppConstants.deleteConfirmMessage}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await foodProvider.deleteFood(food.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppConstants.deleteSuccess),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}

