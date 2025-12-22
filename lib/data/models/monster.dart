import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/gen_assets.dart';

part 'monster.freezed.dart';
part 'monster.g.dart';

/// モンスターの進化段階
@JsonEnum()
enum EvolutionStage {
  /// 卵状態
  egg,

  /// 幼体（孵化直後）
  baby,

  /// 成長中
  teen,

  /// 成体（完全体）
  adult,
}

/// モンスターデータモデル
@freezed
class Monster with _$Monster {
  const Monster._();

  const factory Monster({
    /// モンスターの一意ID
    required int id,

    /// モンスターの名前
    required String name,

    /// 現在の進化段階
    @Default(EvolutionStage.egg) EvolutionStage stage,

    /// このモンスターが1秒あたりに産出するEXP量
    @Default(0.0) double expProductionRate,

    /// 卵を攻撃する力（おともだち効果）
    @Default(1) int attackPower,

    /// このモンスターのレアリティ（1-5、5が最もレア）
    @Default(1) int rarity,

    /// 図鑑に登録済みかどうか
    @Default(false) bool isDiscovered,

    /// 取得日時
    DateTime? obtainedAt,

    /// フレーバーテキスト（図鑑用）
    @Default('') String description,
  }) = _Monster;

  factory Monster.fromJson(Map<String, dynamic> json) =>
      _$MonsterFromJson(json);

  /// 現在の進化段階に応じた画像パスを取得
  String get imagePath {
    if (stage == EvolutionStage.egg) {
      return GenAssets.egg;
    }

    final monsterStage = switch (stage) {
      EvolutionStage.baby => MonsterStage.baby,
      EvolutionStage.teen => MonsterStage.teen,
      EvolutionStage.adult => MonsterStage.adult,
      _ => MonsterStage.baby,
    };

    return GenAssets.monster(id, monsterStage);
  }

  /// 次の進化段階を取得（成体の場合はnull）
  EvolutionStage? get nextStage {
    return switch (stage) {
      EvolutionStage.egg => EvolutionStage.baby,
      EvolutionStage.baby => EvolutionStage.teen,
      EvolutionStage.teen => EvolutionStage.adult,
      EvolutionStage.adult => null,
    };
  }

  /// 完全に進化したかどうか
  bool get isFullyEvolved => stage == EvolutionStage.adult;

  /// 卵状態かどうか
  bool get isEgg => stage == EvolutionStage.egg;
}
