import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/selection_provider.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 앱 시작 시 식품 목록 로드
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
    return Consumer<SelectionProvider>(
      builder: (context, selectionProvider, child) {
        return Scaffold(
          appBar: selectionProvider.isSelectionMode
              ? _buildSelectionAppBar(context, selectionProvider)
              : _buildNormalAppBar(context),
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
                    _RemainingFoodList(
                      onTap: (food) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailScreen(food: food),
                          ),
                        ).then((_) {
                          // 상세 화면에서 돌아왔을 때 리스트 새로고침
                          if (context.mounted) {
                            context.read<FoodProvider>().loadFoods();
                          }
                        });
                      },
                    ),
                    _ConsumedFoodList(
                      onTap: (food) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodDetailScreen(food: food),
                          ),
                        ).then((_) {
                          // 상세 화면에서 돌아왔을 때 리스트 새로고침
                          if (context.mounted) {
                            context.read<FoodProvider>().loadFoods();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFoodScreen(),
                ),
              );
              
              // 추가 성공 시 리스트 새로고침
              if (result == true && mounted) {
                if (context.mounted) {
                  context.read<FoodProvider>().loadFoods();
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text(AppConstants.addFoodButton),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
  
  /// 일반 AppBar 빌더
  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    return AppBar(
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
        // 다중 선택 버튼 (신선하게 보관중 탭에서만)
        if (_tabController.index == 0)
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              context.read<SelectionProvider>().startSelectionMode();
            },
            tooltip: '다중 선택',
          ),
        
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
    );
  }
  
  /// 선택 모드 AppBar 빌더
  PreferredSizeWidget _buildSelectionAppBar(BuildContext context, SelectionProvider selectionProvider) {
    return AppBar(
      title: Text('${selectionProvider.selectedCount}개 선택됨'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          selectionProvider.exitSelectionMode();
        },
      ),
      actions: [
        // 전체 선택/해제
        IconButton(
          icon: Icon(selectionProvider.selectedCount == _getCurrentFoods().length
              ? Icons.check_box
              : Icons.check_box_outline_blank),
          onPressed: () {
            if (selectionProvider.selectedCount == _getCurrentFoods().length) {
              selectionProvider.clearSelection();
            } else {
              final allIds = _getCurrentFoods().map((food) => food.id).cast<String>().toList();
              selectionProvider.selectAll(allIds);
            }
          },
          tooltip: '전체 선택',
        ),
        
        // 삭제 버튼
        if (selectionProvider.selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, selectionProvider),
            tooltip: '선택된 항목 삭제',
          ),
      ],
    );
  }
  
  /// 현재 탭의 식품 목록 반환
  List<dynamic> _getCurrentFoods() {
    final foodProvider = context.read<FoodProvider>();
    return _tabController.index == 0 
        ? foodProvider.remainingFoods 
        : foodProvider.consumedFoods;
  }
  
  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmation(BuildContext context, SelectionProvider selectionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택된 항목 삭제'),
        content: Text('${selectionProvider.selectedCount}개의 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedItems(context, selectionProvider);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
  
  /// 선택된 항목들 삭제
  Future<void> _deleteSelectedItems(BuildContext context, SelectionProvider selectionProvider) async {
    try {
      final foodProvider = context.read<FoodProvider>();
      final selectedIds = selectionProvider.getSelectedIds();
      
      await foodProvider.deleteMultipleFoods(selectedIds);
      
      selectionProvider.exitSelectionMode();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedIds.length}개의 항목이 삭제되었습니다'),
            backgroundColor: AppConstants.freshGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: AppConstants.dangerRed,
          ),
        );
      }
    }
  }
}

/// 신선하게 보관중인 식품 리스트
class _RemainingFoodList extends StatelessWidget {
  final Function(dynamic)? onTap;

  const _RemainingFoodList({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, FilterProvider>(
      builder: (context, foodProvider, filterProvider, child) {
        if (foodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (foodProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  foodProvider.error ?? '오류가 발생했습니다',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => foodProvider.loadFoods(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 필터 적용
        var foods = foodProvider.remainingFoods;
        foods = filterProvider.applyFilters(foods);

        if (foods.isEmpty) {
          return AnimatedFoodList(
            foods: [],
            isConsumed: false,
            onTap: onTap,
            emptyMessage: filterProvider.hasActiveFilters
                ? '검색 조건에 맞는 식품이 없습니다'
                : '아직 등록된 식품이 없습니다\n+ 버튼을 눌러 식품을 추가해보세요!',
            emptyIcon: filterProvider.hasActiveFilters
                ? Icons.search_off
                : Icons.add_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await foodProvider.loadFoods();
          },
          child: Consumer<SelectionProvider>(
            builder: (context, selectionProvider, child) {
              return AnimatedFoodList(
                foods: foods,
                isConsumed: false,
                onTap: onTap,
                onCheckChanged: selectionProvider.isSelectionMode 
                    ? null  // 다중 선택 모드일 때는 체크박스 변경 비활성화
                    : (food, isChecked) {
                        if (isChecked == true) {
                          foodProvider.markAsConsumed(food.id);
                        } else {
                          foodProvider.markAsUnconsumed(food.id);
                        }
                      },
                onDelete: (food) {
                  _showDeleteConfirmation(context, food, foodProvider);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic food, FoodProvider foodProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식품 삭제'),
        content: Text('${food.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await foodProvider.deleteFood(food.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppConstants.deleteSuccess),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// 소비 완료된 식품 리스트
class _ConsumedFoodList extends StatelessWidget {
  final Function(dynamic)? onTap;

  const _ConsumedFoodList({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FoodProvider, FilterProvider>(
      builder: (context, foodProvider, filterProvider, child) {
        if (foodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (foodProvider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  foodProvider.error ?? '오류가 발생했습니다',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => foodProvider.loadFoods(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 필터 적용
        var foods = foodProvider.consumedFoods;
        foods = filterProvider.applyFilters(foods);

        if (foods.isEmpty) {
          return AnimatedFoodList(
            foods: [],
            isConsumed: true,
            onTap: onTap,
            emptyMessage: filterProvider.hasActiveFilters
                ? '검색 조건에 맞는 식품이 없습니다'
                : '아직 소비 완료된 식품이 없습니다',
            emptyIcon: filterProvider.hasActiveFilters
                ? Icons.search_off
                : Icons.check_circle_outline,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await foodProvider.loadFoods();
          },
          child: Consumer<SelectionProvider>(
            builder: (context, selectionProvider, child) {
              return AnimatedFoodList(
                foods: foods,
                isConsumed: true,
                onTap: onTap,
                onCheckChanged: selectionProvider.isSelectionMode 
                    ? null  // 다중 선택 모드일 때는 체크박스 변경 비활성화
                    : (food, isChecked) {
                        if (isChecked == true) {
                          foodProvider.markAsConsumed(food.id);
                        } else {
                          foodProvider.markAsUnconsumed(food.id);
                        }
                      },
                onDelete: (food) {
                  _showDeleteConfirmation(context, food, foodProvider);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic food, FoodProvider foodProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식품 삭제'),
        content: Text('${food.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await foodProvider.deleteFood(food.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppConstants.deleteSuccess),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
