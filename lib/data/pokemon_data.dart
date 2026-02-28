import 'package:flutter/material.dart';

class PokemonEntry {
  final String katakana; // フシギダネ
  final String hiragana; // ふしぎだね
  final Color color;
  final int pokedexId; // 全国図鑑ナンバー

  const PokemonEntry({
    required this.katakana,
    required this.hiragana,
    required this.color,
    required this.pokedexId,
  });

  List<String> get chars => katakana.split('');

  /// PokeAPI 公式アートワーク URL
  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master'
      '/sprites/pokemon/other/official-artwork/$pokedexId.png';
}

/// カタカナ1文字あたりのストローク数（濁音・半濁音・小文字・長音符含む）
const Map<String, int> _strokeCounts = {
  // ア行
  'ア': 2, 'イ': 2, 'ウ': 3, 'エ': 3, 'オ': 3,
  // カ行（清音）
  'カ': 2, 'キ': 3, 'ク': 2, 'ケ': 3, 'コ': 2,
  // カ行（濁音）゛=2画
  'ガ': 4, 'ギ': 5, 'グ': 4, 'ゲ': 5, 'ゴ': 4,
  // サ行（清音）
  'サ': 3, 'シ': 3, 'ス': 2, 'セ': 2, 'ソ': 2,
  // サ行（濁音）゛=2画
  'ザ': 5, 'ジ': 5, 'ズ': 4, 'ゼ': 4, 'ゾ': 4,
  // タ行（清音）
  'タ': 3, 'チ': 3, 'ツ': 3, 'テ': 3, 'ト': 2,
  // タ行（濁音）゛=2画
  'ダ': 5, 'ヂ': 5, 'ヅ': 5, 'デ': 5, 'ド': 4,
  // ナ行
  'ナ': 2, 'ニ': 2, 'ヌ': 2, 'ネ': 4, 'ノ': 1,
  // ハ行（清音）
  'ハ': 3, 'ヒ': 2, 'フ': 1, 'ヘ': 1, 'ホ': 4,
  // ハ行（濁音）゛=2画
  'バ': 5, 'ビ': 4, 'ブ': 3, 'ベ': 3, 'ボ': 6,
  // ハ行（半濁音）
  'パ': 4, 'ピ': 3, 'プ': 2, 'ペ': 2, 'ポ': 5,
  // マ行
  'マ': 2, 'ミ': 3, 'ム': 2, 'メ': 2, 'モ': 3,
  // ヤ行
  'ヤ': 3, 'ユ': 2, 'ヨ': 3,
  // ラ行
  'ラ': 2, 'リ': 2, 'ル': 2, 'レ': 1, 'ロ': 1,
  // ワ行
  'ワ': 2, 'ヲ': 3, 'ン': 2,
  // 小文字
  'ァ': 2, 'ィ': 2, 'ゥ': 3, 'ェ': 3, 'ォ': 3,
  'ャ': 3, 'ュ': 2, 'ョ': 3, 'ッ': 3,
  // 長音符
  'ー': 1,
};

int strokeCountFor(String char) => _strokeCounts[char] ?? 2;

const List<PokemonEntry> pokemonList = [
  PokemonEntry(katakana: 'ピカチュウ',  hiragana: 'ぴかちゅう',  color: Color(0xFFF5C518), pokedexId: 25),
  PokemonEntry(katakana: 'フシギダネ',  hiragana: 'ふしぎだね',  color: Color(0xFF4CAF50), pokedexId: 1),
  PokemonEntry(katakana: 'ヒトカゲ',   hiragana: 'ひとかげ',   color: Color(0xFFFF5722), pokedexId: 4),
  PokemonEntry(katakana: 'ゼニガメ',   hiragana: 'ぜにがめ',   color: Color(0xFF2196F3), pokedexId: 7),
  PokemonEntry(katakana: 'カビゴン',   hiragana: 'かびごん',   color: Color(0xFF78909C), pokedexId: 143),
  PokemonEntry(katakana: 'イーブイ',   hiragana: 'いーぶい',   color: Color(0xFF8D6E63), pokedexId: 133),
  PokemonEntry(katakana: 'リザードン', hiragana: 'りざーどん', color: Color(0xFFFF7043), pokedexId: 6),
  PokemonEntry(katakana: 'ゲンガー',   hiragana: 'げんがー',   color: Color(0xFF7B1FA2), pokedexId: 94),
  PokemonEntry(katakana: 'ミュウ',     hiragana: 'みゅう',     color: Color(0xFFEC407A), pokedexId: 151),
  PokemonEntry(katakana: 'ルカリオ',   hiragana: 'るかりお',   color: Color(0xFF1565C0), pokedexId: 448),
  PokemonEntry(katakana: 'ニャース',   hiragana: 'にゃーす',   color: Color(0xFFFFCC80), pokedexId: 52),
  PokemonEntry(katakana: 'コダック',   hiragana: 'こだっく',   color: Color(0xFFFFD54F), pokedexId: 54),
  PokemonEntry(katakana: 'ヤドン',     hiragana: 'やどん',     color: Color(0xFFF48FB1), pokedexId: 79),
  PokemonEntry(katakana: 'ラプラス',   hiragana: 'らぷらす',   color: Color(0xFF80DEEA), pokedexId: 131),
  PokemonEntry(katakana: 'プリン',     hiragana: 'ぷりん',     color: Color(0xFFFF80AB), pokedexId: 39),
  PokemonEntry(katakana: 'ロコン',     hiragana: 'ろこん',     color: Color(0xFFFF8A65), pokedexId: 37),
  PokemonEntry(katakana: 'メタモン',   hiragana: 'めたもん',   color: Color(0xFF9575CD), pokedexId: 132),
  PokemonEntry(katakana: 'ハピナス',   hiragana: 'はぴなす',   color: Color(0xFFFFB3C1), pokedexId: 242),
  PokemonEntry(katakana: 'マリルリ',   hiragana: 'まりるり',   color: Color(0xFF42A5F5), pokedexId: 184),
  PokemonEntry(katakana: 'リオル',     hiragana: 'りおる',     color: Color(0xFF1E88E5), pokedexId: 447),
  PokemonEntry(katakana: 'ゾロア',     hiragana: 'ぞろあ',     color: Color(0xFF616161), pokedexId: 570),
  PokemonEntry(katakana: 'ポッチャマ', hiragana: 'ぽっちゃま', color: Color(0xFF0288D1), pokedexId: 393),
  PokemonEntry(katakana: 'ヒコザル',   hiragana: 'ひこざる',   color: Color(0xFFE64A19), pokedexId: 390),
  PokemonEntry(katakana: 'ナエトル',   hiragana: 'なえとる',   color: Color(0xFF388E3C), pokedexId: 387),
  PokemonEntry(katakana: 'ガブリアス', hiragana: 'がぶりあす', color: Color(0xFF1565C0), pokedexId: 445),
];
