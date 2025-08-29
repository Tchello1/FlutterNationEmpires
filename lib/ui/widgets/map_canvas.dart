import 'dart:math';
import 'package:flutter/material.dart';
import '../../persistencia/entidade/mapa_hex.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.mapa,
    required this.zoom,
    this.baseHex = 25.0,
    this.margin = 8.0,
    this.selecionado,
    required this.onTapHex,
  });

  final List<MapaHex> mapa;
  final double zoom;     // 0.8..2.0
  final double baseHex;  // tamanho base do hex
  final double margin;
  final MapaHex? selecionado;
  final ValueChanged<MapaHex?> onTapHex;

  // paleta de biomas
  static final Map<String, Color> _corBioma = {
    'agua': Colors.blue,
    'floresta': Colors.green,
    'planicie': Colors.lightGreen,
    'montanha': Colors.grey,
  };

  // mistura com canais normalizados (0..1) – evita APIs deprecadas
  Color _corComposta(Map<String, double> comp) {
    final total = comp.values.fold<double>(0, (a, b) => a + b);
    final norm = total == 0 ? comp : {for (final e in comp.entries) e.key: e.value / total};

    double a = 0, r = 0, g = 0, b = 0;
    norm.forEach((bioma, peso) {
      final c = _corBioma[bioma] ?? Colors.purple;
      // novos canais como double 0..1
      a += c.a * peso;
      r += c.r * peso;
      g += c.g * peso;
      b += c.b * peso;
    });

    // clamp 0..1 e converte pra RGBO (0..255 + alpha 0..1)
    final aa = a.clamp(0.0, 1.0).toDouble();
    final rr = (r.clamp(0.0, 1.0) * 255.0).toDouble().clamp(0.0, 255.0).round();
    final gg = (g.clamp(0.0, 1.0) * 255.0).toDouble().clamp(0.0, 255.0).round();
    final bb = (b.clamp(0.0, 1.0) * 255.0).toDouble().clamp(0.0, 255.0).round();

    return Color.fromRGBO(rr, gg, bb, aa);
  }

  // --------- helpers geométricos ----------
  Offset _centroDoHex(MapaHex hex, double hexSize) {
    final double w = hexSize * 2;
    final double h = sqrt(3) * hexSize;
    final double x = hex.q * (w * 0.75) + hexSize + margin;
    final double y = hex.r * h + (hex.q.isOdd ? h / 2 : 0) + hexSize + margin;
    return Offset(x, y);
  }

  Size _gridBoundsFor(double hexSize) {
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (final hex in mapa) {
      final c = _centroDoHex(hex, hexSize);
      for (int i = 0; i < 6; i++) {
        final double angle = (pi / 180) * (60 * i - 30);
        final vx = c.dx + hexSize * cos(angle);
        final vy = c.dy + hexSize * sin(angle);
        if (vx < minX) {
          minX = vx;
        } else if (vx > maxX) {
          maxX = vx;
        }
        if (vy < minY) {
          minY = vy;
        } else if (vy > maxY) {
          maxY = vy;
        }
      }
    }
    return Size(maxX - minX + margin, maxY - minY + margin);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size baseSize = _gridBoundsFor(baseHex);
        final double scaleW = constraints.maxWidth / (baseSize.width + 16);
        final double scaleH = constraints.maxHeight / (baseSize.height + 16);
        final double fitScale = min(scaleW, scaleH).clamp(0.5, 3.0);
        final double hexSize = (baseHex * fitScale * zoom).clamp(10.0, 60.0);
        final Size finalSize = _gridBoundsFor(hexSize);

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final pos = d.localPosition;
              MapaHex? encontrado;
              double melhor = double.infinity;

              for (final hex in mapa) {
                final c = _centroDoHex(hex, hexSize);
                final dist = (pos - c).distance;
                if (dist <= hexSize * 0.95 && dist < melhor) {
                  melhor = dist;
                  encontrado = hex;
                }
              }
              onTapHex(encontrado);
            },
            child: SizedBox(
              width: finalSize.width,
              height: finalSize.height,
              child: CustomPaint(
                painter: _MapaPainter(
                  mapa: mapa,
                  hexSize: hexSize,
                  margin: margin,
                  corComposta: _corComposta,
                  selecionado: selecionado,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapaPainter extends CustomPainter {
  final List<MapaHex> mapa;
  final double hexSize;
  final double margin;
  final Color Function(Map<String, double>) corComposta;
  final MapaHex? selecionado;

  _MapaPainter({
    required this.mapa,
    required this.hexSize,
    required this.margin,
    required this.corComposta,
    required this.selecionado,
  });

  late final double w = hexSize * 2;
  late final double h = sqrt(3) * hexSize;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeNeutral = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      // was: Colors.black.withOpacity(0.35)
      ..color = Colors.black.withValues(alpha: 0.35);

    final fill = Paint()..style = PaintingStyle.fill;

    for (final hex in mapa) {
      final double x = hex.q * (w * 0.75) + hexSize + margin;
      final double y = hex.r * h + (hex.q.isOdd ? h / 2 : 0) + hexSize + margin;

      final path = _hexPath(Offset(x, y), hexSize);

      // fill
      fill.color = corComposta(hex.composicao);
      canvas.drawPath(path, fill);

      // borda por dono
      Paint border = strokeNeutral;
      if (hex.nacaoId == 1) {
        border = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.greenAccent;
      } else if (hex.nacaoId == 2) {
        border = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.redAccent;
      }
      canvas.drawPath(path, border);

      // halo seleção
      if (selecionado == hex) {
        final halo = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          // was: Colors.white.withOpacity(0.9)
          ..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawPath(path, halo);
      }
    }
  }

  Path _hexPath(Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (pi / 180) * (60 * i - 30); // pointy-top
      final Offset v = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(v.dx, v.dy);
      } else {
        path.lineTo(v.dx, v.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MapaPainter old) =>
      old.mapa != mapa ||
      old.selecionado != selecionado ||
      old.hexSize != hexSize ||
      old.margin != margin;
}
