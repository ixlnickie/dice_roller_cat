import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const DiceApp());

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DiceScreen(),
      );
}

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});
  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with TickerProviderStateMixin {
  int leftValue = 1;
  int rightValue = 6;
  bool isRolling = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void rollDice() {
    if (isRolling) return;
    setState(() {
      isRolling = true;
      leftValue = math.Random().nextInt(6) + 1;
      rightValue = math.Random().nextInt(6) + 1;
    });

    _controller.forward(from: 0).then((_) {
      setState(() => isRolling = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFF4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Dice3D(value: leftValue, controller: _controller),
                const SizedBox(width: 80),
                Dice3D(value: rightValue, controller: _controller),
              ],
            ),
            const SizedBox(height: 120),
            GestureDetector(
              onTap: rollDice,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8BFD8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isRolling ? "..." : "БРОСИТЬ",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Created by ixlnickie 🐾",
              style: TextStyle(color: Color(0xFFD8BFD8), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Dice3D extends StatelessWidget {
  final int value;
  final AnimationController controller;

  const Dice3D({super.key, required this.value, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double p = controller.value;
        double rotX = controller.isAnimating ? p * math.pi * 4 : 0.0;
        double rotY = controller.isAnimating ? p * math.pi * 2 : 0.0;

        final List<Map<String, dynamic>> faces = [
          {'v': value, 'rx': 0.0, 'ry': 0.0},
          {'v': 7 - value, 'rx': math.pi, 'ry': 0.0},
          {'v': 2, 'rx': -math.pi / 2, 'ry': 0.0},
          {'v': 5, 'rx': math.pi / 2, 'ry': 0.0},
          {'v': 3, 'rx': 0.0, 'ry': math.pi / 2},
          {'v': 4, 'rx': 0.0, 'ry': -math.pi / 2},
        ];

        faces.sort((a, b) => _getZ(a['rx'], a['ry'], rotX, rotY)
            .compareTo(_getZ(b['rx'], b['ry'], rotX, rotY)));

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotX)
            ..rotateY(rotY),
          child: Stack(
            alignment: Alignment.center,
            children: faces.map((f) => _buildFace(f['v'], f['rx'], f['ry'])).toList(),
          ),
        );
      },
    );
  }

  double _getZ(double rx, double ry, double tx, double ty) {
    return (Matrix4.identity()
          ..rotateX(tx)..rotateY(ty)
          ..rotateX(rx)..rotateY(ry)
          ..translate(0.0, 0.0, 50.0)).storage[14];
  }

  Widget _buildFace(int val, double rx, double ry) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateX(rx)..rotateY(ry)
        ..translate(0.0, 0.0, 50.0),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white, // Теперь всегда белый
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        child: CustomPaint(painter: DiceDotsPainter(val)),
      ),
    );
  }
}

class DiceDotsPainter extends CustomPainter {
  final int val;
  DiceDotsPainter(this.val);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF333333);
    double r = size.width * 0.08, c = size.width / 2, l = size.width * 0.25, h = size.width * 0.75;
    void d(double x, double y) => canvas.drawCircle(Offset(x, y), r, paint);
    if (val % 2 != 0) d(c, c);
    if (val >= 2) { d(l, l); d(h, h); }
    if (val >= 4) { d(h, l); d(l, h); }
    if (val == 6) { d(l, c); d(h, c); }
  }
  @override bool shouldRepaint(old) => false;
}