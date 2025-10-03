import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../widgets/food_list_item.dart';
import '../utils/constants.dart';
import 'add_food_screen.dart';
import 'settings_screen.dart';

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
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭 1: 신선하게 보관중 (남은 음식)
          _RemainingFoodList(),
          // 탭 2: 소비 완료! (먹은 음식)
          _ConsumedFoodList(),
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
  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final remainingFoods = foodProvider.remainingFoods;

        // 로딩 중
        if (foodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 빈 상태
        if (remainingFoods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.emptyRemainingFood,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        // 리스트 표시
        return RefreshIndicator(
          onRefresh: () => foodProvider.loadFoods(),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppConstants.defaultPadding,
              bottom: 80, // FAB 공간 확보
            ),
            itemCount: remainingFoods.length,
            itemBuilder: (context, index) {
              final food = remainingFoods[index];
              return FoodListItem(
                food: food,
                onTap: () {
                  // TODO: 식품 상세 화면으로 이동
                },
                onCheckChanged: (value) async {
                  if (value == true) {
                    await foodProvider.markAsConsumed(food.id);
                  }
                },
                onDelete: () async {
                  // 삭제 확인 다이얼로그
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
              );
            },
          ),
        );
      },
    );
  }
}

/// 소비 완료 음식 리스트
class _ConsumedFoodList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, child) {
        final consumedFoods = foodProvider.consumedFoods;

        // 로딩 중
        if (foodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 빈 상태
        if (consumedFoods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.emptyConsumedFood,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        // 리스트 표시
        return RefreshIndicator(
          onRefresh: () => foodProvider.loadFoods(),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppConstants.defaultPadding,
              bottom: 80,
            ),
            itemCount: consumedFoods.length,
            itemBuilder: (context, index) {
              final food = consumedFoods[index];
              return FoodListItem(
                food: food,
                isConsumed: true,
                onTap: () {
                  // TODO: 식품 상세 화면으로 이동
                },
                onCheckChanged: (value) async {
                  if (value == false) {
                    // 다시 보관 중으로 변경
                    await foodProvider.markAsUnconsumed(food.id);
                  }
                },
                onDelete: () async {
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
              );
            },
          ),
        );
      },
    );
  }
}

