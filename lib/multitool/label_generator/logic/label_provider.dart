import 'package:flutter/material.dart';
import 'package:gridly/multitool/label_generator/models/label_models.dart';

class LabelProvider extends ChangeNotifier {
  static const double maxLabelLengthMm = 297.0;
  static const int maxPages = 10;
  static const double safePrintMarginMm = 3.0;

  final List<Label> _pages = [Label()];
  int _currentPageIndex = 0;
  bool _isPreviewVertical = false;
  bool _fillA4Page = false;
  bool _useSafePrintMargin = false;
  bool _isSettingsCollapsed = false;
  String? _selectedBlockId;

  Label get label => _pages[_currentPageIndex];
  List<Label> get labels => List.unmodifiable(_pages);
  int get currentPageIndex => _currentPageIndex;
  int get pagesCount => _pages.length;
  bool get canAddPage => _pages.length < maxPages;
  bool get hasAnyContent => _pages.any((page) => page.blocks.isNotEmpty);
  bool get isPreviewVertical => _isPreviewVertical;
  bool get fillA4Page => _fillA4Page;
  bool get useSafePrintMargin => _useSafePrintMargin;
  bool get isSettingsCollapsed => _isSettingsCollapsed;
  String? get selectedBlockId => _selectedBlockId;
  LabelBlock? get selectedBlock {
    final selectedId = _selectedBlockId;
    if (selectedId == null) {
      return null;
    }

    for (final block in label.blocks) {
      if (block.id == selectedId) {
        return block;
      }
    }
    return null;
  }

  void _updateCurrentLabel(Label updatedLabel) {
    _pages[_currentPageIndex] = updatedLabel;
    notifyListeners();
  }

  /// Dodaj nową stronę i przejdź do niej
  bool addPage() {
    if (!canAddPage) {
      return false;
    }

    _pages.add(Label(height: label.height));
    _currentPageIndex = _pages.length - 1;
    _selectedBlockId = null;
    notifyListeners();
    return true;
  }

  /// Ustaw aktywną stronę
  void setCurrentPage(int index) {
    if (index < 0 || index >= _pages.length || index == _currentPageIndex) {
      return;
    }
    _currentPageIndex = index;
    final blocks = label.blocks;
    _selectedBlockId = blocks.isNotEmpty ? blocks.first.id : null;
    notifyListeners();
  }

  /// Przejdź do poprzedniej strony
  void previousPage() {
    setCurrentPage(_currentPageIndex - 1);
  }

  /// Przejdź do następnej strony
  void nextPage() {
    setCurrentPage(_currentPageIndex + 1);
  }

  /// Ustaw orientację podglądu paska
  void setPreviewVertical(bool isVertical) {
    if (_isPreviewVertical == isVertical) return;
    _isPreviewVertical = isVertical;
    notifyListeners();
  }

  /// Ustaw tryb zapełnienia całej strony A4
  void setFillA4Page(bool fill) {
    if (_fillA4Page == fill) return;
    _fillA4Page = fill;
    notifyListeners();
  }

  /// Ustaw tryb bezpiecznego marginesu drukarki
  void setUseSafePrintMargin(bool value) {
    if (_useSafePrintMargin == value) return;
    _useSafePrintMargin = value;
    notifyListeners();
  }

  void toggleSettingsCollapsed() {
    _isSettingsCollapsed = !_isSettingsCollapsed;
    notifyListeners();
  }

  /// Zmień wysokość etykiety
  void setHeight(LabelHeight height) {
    _updateCurrentLabel(label.copyWith(height: height));
  }

  /// Dodaj nowy blok
  bool addBlock(ModuleWidth width) {
    final newTotalWidth = label.totalWidthMm + width.widthMm;
    if (newTotalWidth > maxLabelLengthMm) {
      return false;
    }

    final newBlock = LabelBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      width: width,
      text: '',
    );
    final blocks = List<LabelBlock>.from(label.blocks)..add(newBlock);
    _selectedBlockId = newBlock.id;
    _updateCurrentLabel(label.copyWith(blocks: blocks));
    return true;
  }

  /// Usuń blok
  void removeBlock(String id) {
    final blocks = label.blocks.where((b) => b.id != id).toList();
    if (_selectedBlockId == id) {
      _selectedBlockId = blocks.isNotEmpty ? blocks.first.id : null;
    }
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  void selectBlock(String id) {
    if (_selectedBlockId == id) {
      return;
    }
    _selectedBlockId = id;
    notifyListeners();
  }

  /// Aktualizuj tekst bloku
  void updateBlockText(String id, String text) {
    final blocks = label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(text: text);
      }
      return b;
    }).toList();
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Zmień kolor tła bloku
  void updateBlockColor(String id, Color color) {
    final blocks = label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(backgroundColor: color);
      }
      return b;
    }).toList();
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Przełącz orientację tekstu
  void toggleBlockTextOrientation(String id) {
    final blocks = label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(isVerticalText: !b.isVerticalText);
      }
      return b;
    }).toList();
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Zmień szerokość bloku
  bool updateBlockWidth(String id, ModuleWidth width) {
    final currentBlockIndex = label.blocks.indexWhere((b) => b.id == id);
    if (currentBlockIndex == -1) {
      return false;
    }

    final currentBlock = label.blocks[currentBlockIndex];

    final newTotalWidth =
        (label.totalWidthMm - currentBlock.widthMm) + width.widthMm;
    if (newTotalWidth > maxLabelLengthMm) {
      return false;
    }

    final blocks = label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(width: width);
      }
      return b;
    }).toList();
    _updateCurrentLabel(label.copyWith(blocks: blocks));
    return true;
  }

  /// Przesuń blok w lewo
  void moveBlockLeft(String id) {
    final index = label.blocks.indexWhere((b) => b.id == id);
    if (index > 0) {
      final blocks = List<LabelBlock>.from(label.blocks);
      final block = blocks.removeAt(index);
      blocks.insert(index - 1, block);
      _updateCurrentLabel(label.copyWith(blocks: blocks));
    }
  }

  /// Przesuń blok w prawo
  void moveBlockRight(String id) {
    final index = label.blocks.indexWhere((b) => b.id == id);
    if (index < label.blocks.length - 1) {
      final blocks = List<LabelBlock>.from(label.blocks);
      final block = blocks.removeAt(index);
      blocks.insert(index + 1, block);
      _updateCurrentLabel(label.copyWith(blocks: blocks));
    }
  }

  /// Przesuń pole o jedno miejsce w górę listy
  void moveBlockUpAt(int index) {
    if (index <= 0 || index >= label.blocks.length) {
      return;
    }
    final blocks = List<LabelBlock>.from(label.blocks);
    final moved = blocks.removeAt(index);
    blocks.insert(index - 1, moved);
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Przesuń pole o jedno miejsce w dół listy
  void moveBlockDownAt(int index) {
    if (index < 0 || index >= label.blocks.length - 1) {
      return;
    }
    final blocks = List<LabelBlock>.from(label.blocks);
    final moved = blocks.removeAt(index);
    blocks.insert(index + 1, moved);
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Zmień kolejność pól metodą drag & drop
  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= label.blocks.length) {
      return;
    }

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    if (targetIndex < 0 || targetIndex >= label.blocks.length) {
      return;
    }

    final blocks = List<LabelBlock>.from(label.blocks);
    final moved = blocks.removeAt(oldIndex);
    blocks.insert(targetIndex, moved);
    _updateCurrentLabel(label.copyWith(blocks: blocks));
  }

  /// Wyczyść wszystkie bloki
  void clear() {
    _selectedBlockId = null;
    _updateCurrentLabel(Label(height: label.height));
  }
}
