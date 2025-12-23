import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/monster.dart';

class FriendMonster extends StatelessWidget {
  final Monster monster;
  final VoidCallback? onTap;

  const FriendMonster({super.key, required this.monster, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // モンスター画像
          Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  // デバッグ用: 背景色をつけない（透過確認のため）
                  // color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  monster.imagePath,
                  fit: BoxFit.contain, // または scaleDown
                  errorBuilder: (_, __, ___) {
                    final emoji = switch (monster.stage) {
                      EvolutionStage.adult => '🐲',
                      EvolutionStage.teen => '🦖',
                      _ => '🐣',
                    };
                    return Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 30)),
                    );
                  },
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -5,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ), // 上下にふわふわ

          const SizedBox(height: 4),

          // 名前（省略）
          // Text(monster.name, style: ...),
        ],
      ),
    );
  }
}
