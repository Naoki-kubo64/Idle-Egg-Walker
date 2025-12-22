import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// クリックエフェクトの種類
enum ClickEffectType {
  exp,    // EXPテキスト
  heart,  // ハートアイコン
  star,   // 星アイコン
}

/// 個別のエフェクトデータ
class ClickEffectItem {
  final String id;
  final Offset position;
  final ClickEffectType type;
  final String? text; // EXPの場合の数値テキスト
  
  // 物理演算用
  final double velocityX;
  final double velocityY;
  
  ClickEffectItem({
    required this.id,
    required this.position,
    required this.type,
    this.text,
    required this.velocityX,
    required this.velocityY,
  });
}

/// クリックエフェクトを管理・表示するオーバーレイWidget
/// 
/// 画面最前面に配置し、タップイベントを受け取ってエフェクトを描画する。
/// 下層へのタッチ透過の設定が可能。
class ClickEffectOverlay extends StatefulWidget {
  final Widget child;
  final bool enableTouch; // タッチ有効化（falseならエフェクト表示のみでタッチは透過）
  
  // 外部からエフェクトを追加するためのコントローラーが必要だが、
  // 今回はProvider経由またはGlobalKeyでアクセスする形を想定
  // 簡易的にNotificationを使用する手もある
  
  const ClickEffectOverlay({
    super.key,
    required this.child,
    this.enableTouch = true,
  });
  
  static ClickEffectOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ClickEffectOverlayState>();
  }

  @override
  State<ClickEffectOverlay> createState() => ClickEffectOverlayState();
}

class ClickEffectOverlayState extends State<ClickEffectOverlay> with TickerProviderStateMixin {
  final List<ClickEffectItem> _items = [];
  final Random _random = Random();
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    // ゲームループ（60FPS）
    _controller = AnimationController(
        vsync: this, duration: const Duration(days: 1))
      ..addListener(_update)
      ..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _update() {
    if (_items.isEmpty) return;
    
    setState(() {
      _items.removeWhere((item) {
        // 更新処理（重力などの簡易物理）
        // オブジェクトを変更せず新しいリストを作るのは重いので、
        // ここでは単純に寿命管理だけ行うか、Mutableなラッパーを使う手が良いが
        // FlutterのRebuildサイクルに乗せるため、新しいリストで管理
        return false;
      });
      // 実際のアニメーションはWidget側でTweenで行う方がFlutterらしい
      // ここではアイテムリストの管理のみ行い、個々のWidgetにアニメーションを任せるアプローチをとる
    });
  }

  /// エフェクトを追加するメソッド（外部から呼ぶ）
  void addEffect(Offset position, {int exp = 1}) {
    // EXPテキスト
    _addExpText(position, exp);
    
    // パーティクル（確率で発生）
    if (_random.nextBool()) _addParticle(position, ClickEffectType.star);
    if (_random.nextDouble() < 0.3) _addParticle(position, ClickEffectType.heart);
  }

  void _addExpText(Offset position, int exp) {
    _addItem(ClickEffectItem(
      id: DateTime.now().microsecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
      position: position,
      type: ClickEffectType.exp,
      text: '+$exp',
      velocityX: (_random.nextDouble() - 0.5) * 5,
      velocityY: -5 - _random.nextDouble() * 5,
    ));
  }
  
  void _addParticle(Offset position, ClickEffectType type) {
    _addItem(ClickEffectItem(
      id: DateTime.now().microsecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
      position: position,
      type: type,
      velocityX: (_random.nextDouble() - 0.5) * 10,
      velocityY: (_random.nextDouble() - 0.5) * 10,
    ));
  }

  void _addItem(ClickEffectItem item) {
    setState(() {
      _items.add(item);
    });
    
    // 1秒後に削除
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
        });
      }
    });
  }

  /// 画面全体のタップ処理
  void _handleTap(TapDownDetails details) {
    if (widget.enableTouch) {
      addEffect(details.globalPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // メインコンテンツ
        widget.child,
        
        // エフェクトレイヤー
        IgnorePointer(
          child: Stack(
            children: _items.map((item) {
              return _AnimatedEffectItem(
                key: ValueKey(item.id),
                item: item,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 個別のアニメーションアイテム Widget
class _AnimatedEffectItem extends StatefulWidget {
  final ClickEffectItem item;

  const _AnimatedEffectItem({super.key, required this.item});

  @override
  State<_AnimatedEffectItem> createState() => _AnimatedEffectItemState();
}

class _AnimatedEffectItemState extends State<_AnimatedEffectItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // フェードアウト
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // 移動（重力付き放物線をTweenで簡易表現）
    // 正確な物理演算ではないが、UIエフェクトとしては十分
    final beginPos = widget.item.position;
    final endPos = beginPos + Offset(
      widget.item.velocityX * 10, // X移動量
      widget.item.velocityY * 10, // Y移動量（上へ）
    );

    _position = Tween<Offset>(begin: beginPos, end: endPos).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // スケール（飛び出す感じ）
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 80),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx - 20, // 中心合わせ
          top: _position.value.dy - 20,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.item.type) {
      case ClickEffectType.exp:
        return Text(
          widget.item.text ?? '',
          style: AppTheme.pixelFont.copyWith(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              const Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        );
      case ClickEffectType.heart:
        return const Text('❤️', style: TextStyle(fontSize: 20));
      case ClickEffectType.star:
        return const Text('⭐', style: TextStyle(fontSize: 20));
    }
  }
}
