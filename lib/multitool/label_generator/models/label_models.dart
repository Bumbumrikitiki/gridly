import 'package:flutter/material.dart';

/// Szerokość modułu rozdzielnic w mm
enum ModuleWidth {
  p1(1, 17.5),
  p2(2, 35.0),
  p3(3, 52.5),
  p4(4, 70.0),
  p5(5, 87.5);

  const ModuleWidth(this.poles, this.widthMm);
  final int poles;
  final double widthMm;

  String get label => '${poles}P';
}

/// Wysokość etykiety
enum LabelHeight {
  standard(15.0, '15mm'),
  large(18.0, '18mm');

  const LabelHeight(this.heightMm, this.label);
  final double heightMm;
  final String label;
}

/// Blok etykiety (jeden moduł)
class LabelBlock {
  final String id;
  ModuleWidth width;
  String text;
  Color backgroundColor;
  bool isVerticalText;

  LabelBlock({
    required this.id,
    this.width = ModuleWidth.p1,
    this.text = '',
    this.backgroundColor = Colors.white,
    this.isVerticalText = false,
  });

  LabelBlock copyWith({
    ModuleWidth? width,
    String? text,
    Color? backgroundColor,
    bool? isVerticalText,
  }) {
    return LabelBlock(
      id: id,
      width: width ?? this.width,
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isVerticalText: isVerticalText ?? this.isVerticalText,
    );
  }

  /// Szerokość w mm
  double get widthMm => width.widthMm;
}

/// Etykieta składająca się z bloków
class Label {
  final LabelHeight height;
  final List<LabelBlock> blocks;

  Label({this.height = LabelHeight.standard, List<LabelBlock>? blocks})
    : blocks = blocks ?? [];

  /// Całkowita szerokość etykiety w mm
  double get totalWidthMm {
    return blocks.fold(0.0, (sum, block) => sum + block.widthMm);
  }

  Label copyWith({LabelHeight? height, List<LabelBlock>? blocks}) {
    return Label(height: height ?? this.height, blocks: blocks ?? this.blocks);
  }
}
