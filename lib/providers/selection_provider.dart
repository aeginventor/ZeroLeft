import 'package:flutter/foundation.dart';

/// 다중 선택 상태를 관리하는 Provider
class SelectionProvider extends ChangeNotifier {
  final Set<String> _selectedItems = <String>{};
  bool _isSelectionMode = false;

  /// 선택된 아이템들
  Set<String> get selectedItems => Set.unmodifiable(_selectedItems);
  
  /// 선택 모드 여부
  bool get isSelectionMode => _isSelectionMode;
  
  /// 선택된 아이템 개수
  int get selectedCount => _selectedItems.length;
  
  /// 아이템이 선택되었는지 확인
  bool isSelected(String id) => _selectedItems.contains(id);
  
  /// 아이템 선택/해제
  void toggleSelection(String id) {
    if (_selectedItems.contains(id)) {
      _selectedItems.remove(id);
    } else {
      _selectedItems.add(id);
    }
    notifyListeners();
  }
  
  /// 모든 아이템 선택
  void selectAll(List<String> allIds) {
    _selectedItems.clear();
    _selectedItems.addAll(allIds);
    notifyListeners();
  }
  
  /// 모든 선택 해제
  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }
  
  /// 선택 모드 시작
  void startSelectionMode() {
    _isSelectionMode = true;
    _selectedItems.clear();
    notifyListeners();
  }
  
  /// 선택 모드 종료
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedItems.clear();
    notifyListeners();
  }
  
  /// 선택된 아이템들 반환
  List<String> getSelectedIds() => _selectedItems.toList();
}
