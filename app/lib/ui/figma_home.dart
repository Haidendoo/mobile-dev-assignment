import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

const figmaHomeBackground = BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0xFF101E19), Color(0xFF101E19), Color(0xFF213A30)],
    stops: [0, .45, 1],
  ),
);

/// Figma file EbPr2cisVRC7wgbkLjKSp9, frame 7:12421.
/// The 640x360 artwork stays centered in the wider 800x360 reference viewport.
class FigmaHome extends StatelessWidget {
  const FigmaHome({
    super.key,
    required this.savedLevelName,
    required this.onContinue,
    required this.onMore,
  });

  final String? savedLevelName;
  final VoidCallback? onContinue;
  final VoidCallback? onMore;
  static const _asset = 'assets/figma/home/';

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: figmaHomeBackground,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / 640,
          constraints.maxHeight / 360,
        );
        final targetHeight = math.max(48.0, 48 / scale);
        final moreTop = math.min(325 - targetHeight / 2, 360 - targetHeight);
        final continueTop = math.min(
          270 - targetHeight / 2,
          moreTop - targetHeight,
        );
        return Center(
          child: SizedBox(
            width: 640 * scale,
            height: 360 * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 640,
                height: 360,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        '${_asset}forest.svg',
                        key: const ValueKey('figma-home-artwork'),
                        width: 640,
                        height: 360,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF101E19),
                              Color(0xFA101E19),
                              Color(0xC4101E19),
                              Color(0x0A101E19),
                              Color(0x00101E19),
                            ],
                            stops: [0, .29, .44, .62, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      top: 42,
                      width: 26,
                      height: 26,
                      child: SvgPicture.asset(
                        '${_asset}seed-crest.svg',
                        width: 26,
                        height: 26,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const Positioned(
                      left: 75,
                      top: 54.5,
                      width: 46,
                      height: .5,
                      child: ColoredBox(color: Color(0xFFA29162)),
                    ),
                    Positioned(left: 39.5, top: 79, child: _title('Forest')),
                    Positioned(left: 38, top: 130.5, child: _title('Sokoban')),
                    const Positioned(
                      left: 43.5,
                      top: 205.5,
                      child: Text(
                        'The Lost Seeds',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontVariations: [ui.FontVariation('wght', 400)],
                          letterSpacing: 0,
                          fontSize: 19.5,
                          height: 24 / 19.5,
                          color: Color(0xFFEACB80),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 43,
                      top: 254,
                      width: 160,
                      height: 32,
                      child: Opacity(
                        opacity: onContinue == null ? .5 : 1,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 3,
                              height: 29,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF946E3F),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 29,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF7DFAB),
                                      Color(0xFFDBB472),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFE9B9),
                                    width: .5,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 9,
                              top: 6.5,
                              child: _label(
                                'Continue',
                                const Color(0xFF111E19),
                              ),
                            ),
                            Positioned(
                              left: 139,
                              top: 8.5,
                              width: 12,
                              height: 12,
                              child: SvgPicture.asset(
                                '${_asset}arrow.svg',
                                width: 12,
                                height: 12,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 44.5,
                      top: 288.5,
                      child: Text(
                        savedLevelName ?? 'No unfinished campaign',
                        style: _sans(9, const Color(0xFFC5D0B2)),
                      ),
                    ),
                    Positioned(
                      left: 43,
                      top: 312.5,
                      width: 77,
                      height: 32,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 29,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E352A),
                                border: Border.all(
                                  color: const Color(0xFF526E55),
                                  width: .5,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 9,
                            top: 6.5,
                            child: _label('More', const Color(0xFFFFF1D2)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 100,
                      top: 321,
                      width: 12,
                      height: 12,
                      child: SvgPicture.asset(
                        '${_asset}dots.svg',
                        width: 12,
                        height: 12,
                        excludeFromSemantics: true,
                      ),
                    ),
                    // Separate transparent 48dp hit regions match the Figma hotspots.
                    Positioned(
                      left: 36,
                      top: continueTop,
                      width: 176,
                      height: targetHeight,
                      child: _hitTarget('Continue', onContinue),
                    ),
                    Positioned(
                      left: 36,
                      top: moreTop,
                      width: 94,
                      height: targetHeight,
                      child: _hitTarget('More', onMore),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0xFF536953), width: .5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  static Widget _title(String text) => Text(
    text,
    textScaler: TextScaler.noScaling,
    style: const TextStyle(
      fontFamily: 'CormorantGaramond',
      fontWeight: FontWeight.w700,
      fontVariations: [ui.FontVariation('wght', 700)],
      fontSize: 62,
      height: 75 / 62,
      letterSpacing: -1.5,
      color: Color(0xFFFFF1D2),
    ),
  );

  static TextStyle _sans(double size, Color color, {bool bold = false}) =>
      TextStyle(
        fontFamily: 'DMSans',
        letterSpacing: 0,
        fontSize: size,
        height: 1.25,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontVariations: [
          const ui.FontVariation('opsz', 14),
          ui.FontVariation('wght', bold ? 700 : 400),
        ],
      );

  static Widget _label(String label, Color color) => ExcludeSemantics(
    child: Text(label, style: _sans(11.5, color, bold: true)),
  );

  static Widget _hitTarget(String label, VoidCallback? callback) => Semantics(
    label: label,
    button: true,
    enabled: callback != null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callback,
        borderRadius: BorderRadius.circular(5),
        child: const SizedBox.expand(),
      ),
    ),
  );
}
