import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import 'figma_scenes.g.dart';

/// Offline Figma layers rendered as native Flutter widgets, never screenshots.
/// Scene data is generated from reviewed MCP context by compile-figma-scenes.py.
class FigmaScene extends StatefulWidget {
  const FigmaScene({
    super.key,
    required this.scene,
    required this.onAction,
    this.text = const {},
    this.replacements = const {},
    this.hidden = const {},
    this.enabled = const {},
    this.dialogOnly = false,
    this.colors = const {},
    this.labels = const {},
  });
  final String scene;
  final void Function(String) onAction;
  final Map<String, String> text;
  final Map<String, Widget> replacements;
  final Set<String> hidden;
  final Map<String, bool> enabled;
  final bool dialogOnly;
  final Map<String, Color> colors;
  final Map<String, String> labels;

  @override
  State<FigmaScene> createState() => _FigmaSceneState();
}

class _FigmaSceneState extends State<FigmaScene> {
  final Set<String> _labels = {};

  void _collectLabels(Map<String, dynamic> n) {
    if (_isControl(n)) {
      _labels.add(n['name'] as String);
      if (widget.labels[n['id']] case final label?) _labels.add(label);
    }
    for (final child in n['children'] as List) {
      _collectLabels(child as Map<String, dynamic>);
    }
  }

  bool _isControl(Map<String, dynamic> n) =>
      n['tag'] == 'a' || n['tag'] == 'button' || n['name'] == 'Undo';

  @override
  Widget build(BuildContext context) {
    final root = figmaScenes[widget.scene] as Map<String, dynamic>;
    _labels.clear();
    _collectLabels(root);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / 800,
          constraints.maxHeight / 360,
        );
        return Center(
          child: SizedBox(
            width: 800 * scale,
            height: 360 * scale,
            child: FittedBox(
              child: SizedBox(
                width: 800,
                height: 360,
                child: widget.dialogOnly
                    ? Stack(
                        children: [
                          const Positioned.fill(
                            child: ColoredBox(color: Color(0xC7091711)),
                          ),
                          _layer(context, _findDialog(root)!, scale),
                        ],
                      )
                    : _content(context, root, scale),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _findDialog(Map<String, dynamic> n) {
    if (n['name'] == 'Dialog') return n;
    for (final child in (n['children'] as List)) {
      final found = _findDialog(child as Map<String, dynamic>);
      if (found != null) return found;
    }
    return null;
  }

  Widget _layer(BuildContext context, Map<String, dynamic> n, double scale) {
    if (widget.hidden.contains(n['id']) || widget.hidden.contains(n['name'])) {
      return const SizedBox.shrink();
    }
    final w = (n['w'] as num?)?.toDouble();
    final h = (n['h'] as num?)?.toDouble();
    final x = (n['x'] as num?)?.toDouble() ?? 0;
    final y = (n['y'] as num?)?.toDouble() ?? 0;
    Widget content = _content(context, n, scale);
    if (_isControl(n) && w != null && h != null) {
      final name = n['name'] as String;
      final active = widget.enabled[name] ?? true;
      final targetW = math.max(w, 48 / scale);
      final targetH = math.max(h, 48 / scale);
      content = Semantics(
        label: widget.labels[n['id']] ?? name,
        button: true,
        enabled: active,
        excludeSemantics: true,
        onTap: active ? () => widget.onAction(name) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: active ? () => widget.onAction(name) : null,
          child: Center(
            child: SizedBox(width: w, height: h, child: content),
          ),
        ),
      );
      return Positioned(
        left: x - (targetW - w) / 2,
        top: y - (targetH - h) / 2,
        width: targetW,
        height: targetH,
        child: content,
      );
    }
    return Positioned(
      left: x,
      top: y,
      right: n['fill'] == true && w == null ? 0 : null,
      bottom: n['fill'] == true && h == null ? 0 : null,
      width: w,
      height: h,
      child: content,
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> n, double scale) {
    final id = n['id'] as String;
    final name = n['name'] as String;
    if (widget.replacements[id] case final replacement?) return replacement;
    if (widget.replacements[name] case final replacement?) return replacement;
    final isText = n['tag'] == 'p';
    Widget content;
    if (n['asset'] case final String asset) {
      content = SvgPicture.asset(asset, fit: BoxFit.contain);
    } else if (isText) {
      content = Text(
        widget.text[id] ?? n['text'] as String? ?? '',
        maxLines: n['w'] == null ? 1 : null,
        style: TextStyle(
          fontFamily: n['font'] as String,
          fontSize: (n['fontSize'] as num).toDouble(),
          fontWeight: n['font'] == 'IBMPlexMono'
              ? FontWeight.w500
              : n['bold'] == true
              ? FontWeight.w700
              : FontWeight.w400,
          fontStyle: n['italic'] == true ? FontStyle.italic : FontStyle.normal,
          fontVariations: n['font'] == 'IBMPlexMono'
              ? null
              : [
                  ui.FontVariation('wght', n['bold'] == true ? 700 : 400),
                  if (n['font'] == 'DMSans') const ui.FontVariation('opsz', 14),
                ],
          letterSpacing: (n['tracking'] as num).toDouble(),
          color: widget.colors[id] ?? Color(n['color'] as int? ?? 0xfffff1d2),
          height: 1.2,
        ),
      );
    } else {
      content = Stack(
        clipBehavior: n['clip'] == true ? Clip.hardEdge : Clip.none,
        children: [
          for (final child in n['children'] as List)
            _layer(context, child as Map<String, dynamic>, scale),
        ],
      );
    }
    if (isText) {
      content = ExcludeSemantics(
        excluding: _labels.contains(widget.text[id] ?? n['text']),
        child: content,
      );
    }
    if (n['background'] != null ||
        n['gradient'] != null ||
        n['border'] != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: n['background'] == null ? null : Color(n['background'] as int),
          gradient: n['gradient'] == null
              ? null
              : LinearGradient(
                  colors: (n['gradient'] as List)
                      .map((c) => Color(c as int))
                      .toList(),
                  stops: (n['stops'] as List?)
                      ?.map((x) => (x as num).toDouble())
                      .toList(),
                ),
          borderRadius: BorderRadius.circular((n['radius'] as num).toDouble()),
          border: n['border'] == null
              ? null
              : Border.all(
                  color: Color(n['border'] as int),
                  width: (n['borderWidth'] as num).toDouble(),
                ),
        ),
        child: content,
      );
    }
    if (n['opacity'] case final num opacity) {
      content = Opacity(opacity: opacity.toDouble(), child: content);
    }
    return content;
  }
}
