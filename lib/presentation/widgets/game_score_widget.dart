import 'package:flutter/material.dart';

class GameScoreWidget extends StatelessWidget {
  const GameScoreWidget({super.key, this.gameDuration, this.onRetryTap});
  final String? gameDuration;
  final Function()? onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(50),
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Game Over!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            Text(
              'Your Time : ${gameDuration ?? ''}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            )
          ],
        ));
  }
}
