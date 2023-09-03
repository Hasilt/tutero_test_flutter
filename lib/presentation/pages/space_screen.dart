import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tutero_test_flutter/presentation/widgets/game_score_widget.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  double mouseX = 0;
  double mouseY = 0;
  bool isMouseDown = false;
  final List<Projectile> projectiles = [];
  final random = Random();
  late double viewportWidth;
  late double viewportHeight;
  double mouseAngle = 0;

  bool isGameEnded = false;
  String? gameDuration;

  late Timer spawnTimer;
  late Timer moveTimer;
  late Timer playTimer;

  @override
  void initState() {
    super.initState();
    viewportWidth = 500;
    viewportHeight = 500;
    initGameData();
  }

  initGameData() {
    spawnTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (projectiles.where((element) => !element.isBullet).length < 10) {
        genProjectiles();
      }
    });
    playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final duration = Duration(seconds: timer.tick);
      setState(() {
        gameDuration = formatDuration(duration);
      });
    });
    genProjectiles();
    moveprojectiles();
  }

  @override
  void dispose() {
    spawnTimer.cancel();
    moveTimer.cancel();
    playTimer.cancel();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final hours = (duration.inHours % 60).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void startGame() {
    setState(() {
      projectiles.clear();
      isGameEnded = false;
    });
    initGameData();
  }

  void gameOver() {
    setState(() {
      isGameEnded = true;
    });

    spawnTimer.cancel();
    playTimer.cancel();
    moveTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    viewportWidth = MediaQuery.of(context).size.width;
    viewportHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: isGameEnded
            ? GameScoreWidget(
                gameDuration: gameDuration,
                onRetryTap: () {
                  startGame();
                },
              )
            : Stack(
                children: [
                  Positioned(
                      child: Text(
                    'Timer: ${gameDuration ?? ''}',
                    style: const TextStyle(color: Colors.white),
                  )),
                  GestureDetector(
                    onTap: () {
                      fireBulltet();
                    },
                    child: MouseRegion(
                      onHover: (PointerHoverEvent event) {
                        setState(() {
                          mouseX = event.position.dx;
                          mouseY = event.position.dy;
                        });
                        mouseAngle = atan2(mouseY - viewportHeight / 2,
                            mouseX - viewportWidth / 2);
                      },
                      child: CustomPaint(
                        painter: SpacePainter(
                            mouseX, mouseY, projectiles, mouseAngle),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void fireBulltet() {
    double radius = 5;
    projectiles.add(
      Projectile(
        radius: radius,
        x: mouseX + 20,
        y: mouseY + -15,
        isBullet: true,
        xAngle: cos(mouseAngle),
        yAngle: sin(mouseAngle),
      ),
    );
  }

  void moveprojectiles() {
    moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isGameEnded) {
        return;
      }
      for (final asteroid in projectiles) {
        if (!asteroid.isDestroyed) {
          if (asteroid.isBullet) {
            asteroid.x += asteroid.velocityX * asteroid.xAngle;
            asteroid.y += asteroid.velocityY * asteroid.yAngle;
          } else {
            asteroid.x += asteroid.velocityX;
            asteroid.y += asteroid.velocityY;
          }

          if (!asteroid.isBullet &&
              asteroid.x > (mouseX - asteroid.radius - 10) &&
              asteroid.x < (mouseX + asteroid.radius + 10) &&
              asteroid.y > (mouseY - asteroid.radius - 10) &&
              asteroid.y < (mouseY + asteroid.radius + 10)) {
            gameOver();
          }

          // detect collision with bullet and asteroid
          if (asteroid.isBullet) {
            for (final asteroid2 in projectiles) {
              if (!asteroid2.isBullet && !asteroid2.isDestroyed) {
                final distance = sqrt(
                  pow(asteroid.x - asteroid2.x, 2) +
                      pow(asteroid.y - asteroid2.y, 2),
                );
                if (distance < asteroid.radius + asteroid2.radius) {
                  asteroid2.isDestroyed = true;
                  asteroid.isDestroyed = true;
                }
              }
            }
          }

          // Check if particle is outside the viewport, then reset its position
          if (asteroid.x < -20 ||
              asteroid.x > viewportWidth + 20 ||
              asteroid.y < -20 ||
              asteroid.y > viewportHeight + 20) {
            if (asteroid.isBullet) {
              asteroid.isDestroyed = true;
            } else {
              asteroid.x = asteroid.initX;
              asteroid.y = asteroid.initY;
            }
          }
        }
      }

      setState(() {});
    });
  }

  void genProjectiles() {
    double radius = random.nextInt(50).toDouble() + 5;
    bool genOnXAxis = random.nextBool();

    projectiles.add(
      Projectile(
        radius: radius,
        x: genOnXAxis ? (random.nextDouble() * viewportWidth) - 10 : 0,
        y: genOnXAxis ? 0 : (random.nextDouble() * viewportHeight) - 10,
      ),
    );
  }
}

class Projectile {
  double x;
  double y;
  late double initX;
  late double initY;
  late final double velocityX;
  late final double velocityY;
  bool isDestroyed = false;
  final double radius;
  final bool isBullet;
  final double xAngle;
  final double yAngle;

  Projectile({
    required this.x,
    required this.y,
    required this.radius,
    this.xAngle = 0,
    this.yAngle = 0,
    this.isBullet = false,
  }) {
    final random = Random();
    velocityX = isBullet ? 20 : (random.nextDouble() * 20);
    velocityY = isBullet ? 20 : (random.nextDouble() * 20);

    initX = x;
    initY = y;
  }
}

class SpacePainter extends CustomPainter {
  final List<Projectile> projectiles;
  final double mouseX;
  final double mouseY;
  final double mouseAngle;

  SpacePainter(this.mouseX, this.mouseY, this.projectiles, this.mouseAngle);

  @override
  void paint(Canvas canvas, Size size) {
    for (final asteroid in projectiles) {
      if (!asteroid.isDestroyed) {
        final paint = Paint()
          ..color = asteroid.isBullet ? Colors.white : Colors.red
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
            Offset(asteroid.x, asteroid.y), asteroid.radius, paint);
      }
    }

    // player
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, -10)
      ..lineTo(30, 0)
      ..lineTo(0, 10)
      ..lineTo(5, 0) // little bent aka tail of arrow
      ..close();

    // Translate and rotate the arrow to the mouse position
    canvas.translate(mouseX, mouseY);
    canvas.rotate(mouseAngle);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
