import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../providers/food_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// 식품 등록 화면
class AddFoodScreen extends StatefulWidget {
  final FoodItem? foodToEdit;

  const AddFoodScreen({
    super.key,
    this.foodToEdit,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expiryDate;
  int? _notificationDays;
  String? _selectedCategory;
  
  bool get _isEditing => widget.foodToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // 수정 모드
      final food = widget.foodToEdit!;
      _nameController.text = food.name;
      _purchaseDate = food.purchaseDate;
      _expiryDate = food.expiryDate;
      _notificationDays = food.notificationDays;
      _selectedCategory = food.category;
    } else {
      // 신규 등록 모드: 기본 알림 시점 로드
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final settings = context.read<SettingsProvider>().settings;
        setState(() {
          _notificationDays = settings.defaultNotificationDays;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '식품 수정' : AppConstants.addFoodButton),
        actions: [
          // 저장 버튼
          TextButton.icon(
            onPressed: _saveFood,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // 식품 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppConstants.labelFoodName,
                hintText: AppConstants.hintFoodName,
                prefixIcon: Icon(Icons.food_bank),
              ),
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '식품 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // 카테고리 선택
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: AppConstants.labelCategory,
                prefixIcon: Icon(Icons.category),
              ),
              items: FoodCategories.all.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(
                        FoodCategories.icons[category] ?? '📦',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  // 카테고리 선택 시 기본 유통기한 제안
                  if (_expiryDate == null && value != null) {
                    final defaultDays = FoodCategories.defaultShelfLife[value] ?? 7;
                    _expiryDate = _purchaseDate.add(Duration(days: defaultDays));
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            
            // 구매 날짜
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shopping_cart),
              title: const Text(AppConstants.labelPurchaseDate),
              subtitle: Text(
                app_date_utils.DateUtils.formatKorean(_purchaseDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectPurchaseDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 20),
            
            // 유통기한
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_available,
                color: _expiryDate == null ? Colors.grey : AppConstants.freshGreen,
              ),
              title: const Text(
                '${AppConstants.labelExpiryDate} *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _expiryDate != null
                    ? app_date_utils.DateUtils.formatKorean(_expiryDate!)
                    : AppConstants.hintSelectDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _expiryDate == null ? Colors.grey : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectExpiryDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                side: BorderSide(
                  color: _expiryDate == null
                      ? AppConstants.dangerRed
                      : Colors.grey[300]!,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 알림 시점
            DropdownButtonFormField<int>(
              initialValue: _notificationDays,
              decoration: const InputDecoration(
                labelText: AppConstants.labelNotificationDays,
                prefixIcon: Icon(Icons.notifications_active),
              ),
              items: AppConstants.notificationOptions.map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text(AppConstants.notificationLabels[days] ?? 'D-$days'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _notificationDays = value;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // 안내 메시지
            if (_expiryDate != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppConstants.freshGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: AppConstants.freshGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppConstants.freshGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '알림 정보',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppConstants.freshGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_notificationDays != null) ...[
                      Text(
                        '• 알림 발송일: ${app_date_utils.DateUtils.formatKorean(_expiryDate!.subtract(Duration(days: _notificationDays!)))}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '• 남은 기간: ${app_date_utils.DateUtils.daysBetween(_purchaseDate, _expiryDate!)}일',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 구매 날짜 선택
  Future<void> _selectPurchaseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
        
        // 유통기한이 구매일보다 이전이면 초기화
        if (_expiryDate != null && _expiryDate!.isBefore(_purchaseDate)) {
          _expiryDate = null;
        }
      });
    }
  }

  /// 유통기한 선택
  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? _purchaseDate.add(const Duration(days: 7)),
      firstDate: _purchaseDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  /// 식품 저장
  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('유통기한을 선택해주세요'),
          backgroundColor: AppConstants.dangerRed,
        ),
      );
      return;
    }

    final foodProvider = context.read<FoodProvider>();
    final settings = context.read<SettingsProvider>().settings;

    if (_isEditing) {
      // 수정
      final updatedFood = widget.foodToEdit!.copyWith(
        name: _nameController.text.trim(),
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        notificationDays: _notificationDays ?? settings.defaultNotificationDays,
        category: _selectedCategory,
      );
      
      await foodProvider.updateFood(updatedFood);
    } else {
      // 신규 등록
      final newFood = FoodItem(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate!,
        notificationDays: _notificationDays ?? settings.defaultNotificationDays,
        category: _selectedCategory,
      );
      
      await foodProvider.addFood(newFood);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.saveSuccess),
          backgroundColor: AppConstants.freshGreen,
        ),
      );
    }
  }
}

