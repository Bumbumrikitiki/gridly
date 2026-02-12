import 'package:flutter/material.dart';
import 'package:gridly/multitool/label_generator/models/label_models.dart';

class LabelProvider extends ChangeNotifier {
  Label _label = Label();

  Label get label => _label;

  /// Zmień wysokość etykiety
  void setHeight(LabelHeight height) {
    _label = _label.copyWith(height: height);
    notifyListeners();
  }

  /// Dodaj nowy blok
  void addBlock(ModuleWidth width) {
    final newBlock = LabelBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      width: width,
      text: '',
    );
    final blocks = List<LabelBlock>.from(_label.blocks)..add(newBlock);
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Usuń blok
  void removeBlock(String id) {
    final blocks = _label.blocks.where((b) => b.id != id).toList();
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Aktualizuj tekst bloku
  void updateBlockText(String id, String text) {
    final blocks = _label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(text: text);
      }
      return b;
    }).toList();
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Zmień kolor tła bloku
  void updateBlockColor(String id, Color color) {
    final blocks = _label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(backgroundColor: color);
      }
      return b;
    }).toList();
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Przełącz orientację tekstu
  void toggleBlockTextOrientation(String id) {
    final blocks = _label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(isVerticalText: !b.isVerticalText);
      }
      return b;
    }).toList();
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Zmień szerokość bloku
  void updateBlockWidth(String id, ModuleWidth width) {
    final blocks = _label.blocks.map((b) {
      if (b.id == id) {
        return b.copyWith(width: width);
      }
      return b;
    }).toList();
    _label = _label.copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Przesuń blok w lewo
  void moveBlockLeft(String id) {
    final index = _label.blocks.indexWhere((b) => b.id == id);
    if (index > 0) {
      final blocks = List<LabelBlock>.from(_label.blocks);
      final block = blocks.removeAt(index);
      blocks.insert(index - 1, block);
      _label = _label.copyWith(blocks: blocks);
      notifyListeners();
    }
  }

  /// Przesuń blok w prawo
  void moveBlockRight(String id) {
    final index = _label.blocks.indexWhere((b) => b.id == id);
    if (index < _label.blocks.length - 1) {
      final blocks = List<LabelBlock>.from(_label.blocks);
      final block = blocks.removeAt(index);
      blocks.insert(index + 1, block);
      _label = _label.copyWith(blocks: blocks);
      notifyListeners();
    }
  }

  /// Wyczyść wszystkie bloki
  void clear() {
    _label = Label(height: _label.height);
    notifyListeners();
  }
}
