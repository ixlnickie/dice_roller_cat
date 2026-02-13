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
                _buildDiceWithShadow(leftValue),
                const SizedBox(width: 60),
                _buildDiceWithShadow(rightValue),
              ],
            ),
            const SizedBox(height: 100),
            _buildButton(),
          ],
        ),
      ),
    );
  }

  // Обертка для кубика с тенью под ним
  Widget _buildDiceWithShadow(int value) {
    return Column(
      children: [
        Dice3D(value: value, controller: _controller),
        const SizedBox(height: 20),
        // Мягкая тень на полу
        Container(
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: rollDice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFD8BFD8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          isRolling ? "КАТИМ..." : "БРОСИТЬ",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
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
        
        // В покое углы ровно 0, чтобы было всё видно. В анимации — вращение.
        double rotX = controller.isAnimating ? p * math.pi * 4 : 0.0;
        double rotY = controller.isAnimating ? p * math.pi * 2 : 0.0;

        final List<Map<String, dynamic>> faces = [
          {'v': value, 'rx': 0.0, 'ry': 0.0}, // Передняя
          {'v': 7 - value, 'rx': math.pi, 'ry': 0.0}, // Задняя
          {'v': 2, 'rx': -math.pi / 2, 'ry': 0.0}, // Верхняя
          {'v': 5, 'rx': math.pi / 2, 'ry': 0.0}, // Нижняя
          {'v': 3, 'rx': 0.0, 'ry': math.pi / 2}, // Правая
          {'v': 4, 'rx': 0.0, 'ry': -math.pi / 2}, // Левая
        ];

        // Сортировка для корректного 3D
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12, width: 1),
          // Вместо внешних теней используем градиент для объема внутри грани
          gradient: RadialGradient(
            colors: [Colors.white, Colors.grey.shade100],
            center: Alignment.center,
            radius: 0.8,
          ),
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
    final paint = Paint()..color = const Color(0xFF2D2D2D);
    double r = size.width * 0.08, c = size.width / 2, l = size.width * 0.25, h = size.width * 0.75;
    void d(double x, double y) => canvas.drawCircle(Offset(x, y), r, paint);
    if (val % 2 != 0) d(c, c);
    if (val >= 2) { d(l, l); d(h, h); }
    if (val >= 4) { d(h, l); d(l, h); }
    if (val == 6) { d(l, c); d(h, c); }
  }
  @override bool shouldRepaint(old) => false;
}