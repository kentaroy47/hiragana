import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/pokemon_data.dart';
import '../services/sound_service.dart';
import '../widgets/drawing_canvas.dart';

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  late PokemonEntry _pokemon;
  int _charIndex = 0;
  final List<int> _scores = [];
  bool _showCatchOverlay = false;
  final List<PokemonEntry> _caughtPokemon = [];
  bool _advancing = false;
  int _sessionId = 0; // ValueKey 用：変わると DrawingCanvas が新規作成される
  bool _showHint = false;
  int _streak = 0;

  final _random = math.Random();
  int _prevPokemonIndex = -1;

  @override
  void initState() {
    super.initState();
    final idx = _random.nextInt(pokemonList.length);
    _prevPokemonIndex = idx;
    _pokemon = pokemonList[idx];
  }

  void _pickNewPokemon() {
    int idx;
    do {
      idx = _random.nextInt(pokemonList.length);
    } while (idx == _prevPokemonIndex && pokemonList.length > 1);
    _prevPokemonIndex = idx;
    setState(() {
      _sessionId++;
      _pokemon = pokemonList[idx];
      _charIndex = 0;
      _scores.clear();
      _showCatchOverlay = false;
      _advancing = false;
    });
  }

  void _retrySamePokemon() {
    setState(() {
      _sessionId++;
      _charIndex = 0;
      _scores.clear();
      _showCatchOverlay = false;
      _advancing = false;
      _streak = 0; // リトライでストリークリセット
    });
  }

  void _activateHint() {
    if (_showHint) return;
    setState(() => _showHint = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _onCharComplete(int score) {
    if (_advancing) return;
    _advancing = true;

    _scores.add(score);
    SoundService.playStrokeComplete();
    setState(() {}); // キャラ進捗行の緑チェックを即時表示

    final isLast = _scores.length >= _pokemon.chars.length;

    if (!isLast) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _charIndex++;
          _advancing = false;
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        SoundService.playCatch();
        setState(() {
          _caughtPokemon.add(_pokemon);
          _showCatchOverlay = true;
          _advancing = false;
          _streak++;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chars = _pokemon.chars;
    final currentChar = chars[_charIndex];
    final strokeCount = strokeCountFor(currentChar);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // ─── 左パネル ───
          SizedBox(
            width: 280,
            child: _LeftPanel(
              pokemon: _pokemon,
              caughtPokemon: _caughtPokemon,
              streak: _streak,
              onBack: () => Navigator.pop(context),
            ),
          ),
          // ─── 右パネル ───
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
                  child: Column(
                    children: [
                      // 文字進捗チップ
                      _CharProgressRow(
                        chars: chars,
                        currentIndex: _charIndex,
                        completedCount: _scores.length,
                        pokemonColor: _pokemon.color,
                      ),
                      const SizedBox(height: 6),
                      // ふりがな ＋ ヒントボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _pokemon.hiragana,
                            style: const TextStyle(
                              fontSize: 20,
                              color: AppTheme.textGray,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _HintButton(
                            onPressed: _activateHint,
                            active: _showHint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // お絵かきキャンバス
                      Expanded(
                        child: DrawingCanvas(
                          key: ValueKey('$_sessionId-$_charIndex'),
                          character: currentChar,
                          totalStrokes: strokeCount,
                          onComplete: _onCharComplete,
                          showHint: _showHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // ゲットオーバーレイ
                if (_showCatchOverlay)
                  _CatchOverlay(
                    pokemon: _pokemon,
                    scores: List.unmodifiable(_scores),
                    streak: _streak,
                    onNext: _pickNewPokemon,
                    onRetry: _retrySamePokemon,
                  ),
                // キラキラエフェクト（ゲット時）
                if (_showCatchOverlay)
                  Positioned.fill(
                    child: _ConfettiOverlay(baseColor: _pokemon.color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 左パネル ─────────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final PokemonEntry pokemon;
  final List<PokemonEntry> caughtPokemon;
  final int streak;
  final VoidCallback onBack;

  const _LeftPanel({
    required this.pokemon,
    required this.caughtPokemon,
    required this.streak,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 上部バー
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.home_outlined, size: 16),
                label: const Text('もどる', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkText,
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const Spacer(),
              const _MusicToggleButton(),
            ],
          ),
          const SizedBox(height: 20),

          // ポケモン画像（読込中はポケボールを表示）
          Center(
            child: _PokemonImage(pokemon: pokemon, size: 130),
          ),
          const SizedBox(height: 10),

          const Text(
            'ポケモンのなまえを\nなぞろう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
              height: 1.5,
            ),
          ),

          const Spacer(),

          // ゲット数 ＋ ずかんボタン
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'ゲット：${caughtPokemon.length}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const Spacer(),
                // ずかんボタン
                Tooltip(
                  message: 'ゲットずかん',
                  child: InkWell(
                    onTap: caughtPokemon.isEmpty
                        ? null
                        : () => showDialog(
                              context: context,
                              builder: (_) => _PokedexDialog(
                                caughtPokemon: List.unmodifiable(caughtPokemon),
                              ),
                            ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: caughtPokemon.isEmpty
                            ? const Color(0xFFEEEEEE)
                            : AppTheme.blueAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 22,
                        color: caughtPokemon.isEmpty
                            ? AppTheme.textGray
                            : AppTheme.blueAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // れんぞくゲット表示
          if (streak >= 2) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '$streakれんぞく！',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6D00),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── BGM トグルボタン ──────────────────────────────────────────────────────────

class _MusicToggleButton extends StatefulWidget {
  const _MusicToggleButton();

  @override
  State<_MusicToggleButton> createState() => _MusicToggleButtonState();
}

class _MusicToggleButtonState extends State<_MusicToggleButton> {
  @override
  Widget build(BuildContext context) {
    final playing = SoundService.bgmPlaying;
    return IconButton(
      tooltip: playing ? 'BGMをとめる' : 'BGMをながす',
      icon: Icon(playing ? Icons.music_note : Icons.music_off_outlined),
      color: playing ? AppTheme.blueAccent : AppTheme.textGray,
      onPressed: () {
        SoundService.toggleBgm();
        setState(() {});
      },
    );
  }
}

// ─── ポケモン画像（ネットワーク） ──────────────────────────────────────────────

class _PokemonImage extends StatelessWidget {
  final PokemonEntry pokemon;
  final double size;

  const _PokemonImage({required this.pokemon, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        pokemon.imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          // 読込中はポケボールをプレースホルダーとして表示
          return Center(
            child: _Pokeball(color: pokemon.color, size: size * 0.75),
          );
        },
        errorBuilder: (context, error, stack) {
          // 読込失敗時もポケボールにフォールバック
          return Center(
            child: _Pokeball(color: pokemon.color, size: size * 0.75),
          );
        },
      ),
    );
  }
}

// ─── ポケボール描画 ────────────────────────────────────────────────────────────

class _Pokeball extends StatelessWidget {
  final Color color;
  final double size;

  const _Pokeball({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PokeballPainter(color: color),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  final Color color;
  const _PokeballPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 1;

    // 上半分（テーマカラー）
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi, math.pi, true,
      Paint()..color = color,
    );
    // 下半分（白）
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0, math.pi, true,
      Paint()..color = Colors.white,
    );
    // 外枠
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    // 中央の仕切り線
    canvas.drawLine(
      Offset(cx - r, cy), Offset(cx + r, cy),
      Paint()..color = Colors.black87..strokeWidth = 2.5,
    );
    // 中央ボタン（黒リング）
    canvas.drawCircle(Offset(cx, cy), r * 0.24,
        Paint()..color = Colors.black87);
    // 中央ボタン（白）
    canvas.drawCircle(Offset(cx, cy), r * 0.17,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PokeballPainter old) => old.color != color;
}

// ─── 文字進捗チップ ────────────────────────────────────────────────────────────

class _CharProgressRow extends StatelessWidget {
  final List<String> chars;
  final int currentIndex;
  final int completedCount;
  final Color pokemonColor;

  const _CharProgressRow({
    required this.chars,
    required this.currentIndex,
    required this.completedCount,
    required this.pokemonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(chars.length, (i) {
        final isDone = i < completedCount;
        final isCurrent = i == currentIndex && !isDone;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 58,
          height: 68,
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.greenStroke.withValues(alpha: 0.15)
                : isCurrent
                    ? pokemonColor.withValues(alpha: 0.12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone
                  ? AppTheme.greenStroke
                  : isCurrent
                      ? pokemonColor
                      : const Color(0xFFDDDDDD),
              width: isCurrent ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                chars[i],
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isDone
                      ? AppTheme.greenStroke
                      : isCurrent
                          ? pokemonColor
                          : AppTheme.textGray,
                  height: 1.0,
                ),
              ),
              if (isDone)
                const Icon(Icons.check_circle,
                    size: 13, color: AppTheme.greenStroke),
            ],
          ),
        );
      }),
    );
  }
}

// ─── ゲットオーバーレイ ────────────────────────────────────────────────────────

class _CatchOverlay extends StatefulWidget {
  final PokemonEntry pokemon;
  final List<int> scores;
  final int streak;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const _CatchOverlay({
    required this.pokemon,
    required this.scores,
    required this.streak,
    required this.onNext,
    required this.onRetry,
  });

  @override
  State<_CatchOverlay> createState() => _CatchOverlayState();
}

class _CatchOverlayState extends State<_CatchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _spin;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0, 0.3, curve: Curves.easeIn)),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _spin = Tween<double>(begin: 0, end: math.pi * 6).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0, 0.55, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _starCount {
    if (widget.scores.isEmpty) return 1;
    final avg = widget.scores.reduce((a, b) => a + b) / widget.scores.length;
    return avg.round().clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.pokemon.color;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          opacity: _fade.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 星評価
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final filled = i < _starCount;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled
                              ? const Color(0xFFF5C518)
                              : const Color(0xFFCCCCCC),
                          size: 46,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // ポケモン画像（コーナーに回転ポケボール）
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        children: [
                          _PokemonImage(pokemon: widget.pokemon, size: 150),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Transform.rotate(
                              angle: _spin.value,
                              child: _Pokeball(color: color, size: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 「〇〇をゲット！」
                    Text(
                      '${widget.pokemon.katakana}を',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'ゲット！',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.pinkAccent,
                        shadows: [
                          Shadow(
                            color: AppTheme.pinkAccent.withValues(alpha: 0.25),
                            offset: const Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.pokemon.hiragana,
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppTheme.textGray,
                        letterSpacing: 5,
                      ),
                    ),

                    // れんぞくゲットバッジ
                    if (widget.streak >= 2) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          '🔥 ${widget.streak}れんぞくゲット！',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),

                    // ボタン行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onRetry,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('もういちど',
                              style: TextStyle(fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.darkText,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onNext,
                          icon: const Text('つぎのポケモン',
                              style: TextStyle(fontSize: 16)),
                          label: const Icon(Icons.arrow_forward, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pinkAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── ゲットずかん ダイアログ ──────────────────────────────────────────────────

class _PokedexDialog extends StatelessWidget {
  final List<PokemonEntry> caughtPokemon;

  const _PokedexDialog({required this.caughtPokemon});

  @override
  Widget build(BuildContext context) {
    // 重複排除してゲット回数をカウント
    final counts = <String, int>{};
    final unique = <PokemonEntry>[];
    for (final p in caughtPokemon) {
      if (!counts.containsKey(p.katakana)) unique.add(p);
      counts[p.katakana] = (counts[p.katakana] ?? 0) + 1;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 680,
        height: 460,
        child: Column(
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 12),
              child: Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const Text(
                    'ゲットずかん',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${unique.length}ひき',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // グリッド or 空状態
            Expanded(
              child: unique.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔍', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'まだゲットしていないよ！',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: unique.length,
                      itemBuilder: (context, i) {
                        final p = unique[i];
                        return _PokedexCard(
                          pokemon: p,
                          count: counts[p.katakana]!,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ずかん1枚カード ──────────────────────────────────────────────────────────

class _PokedexCard extends StatelessWidget {
  final PokemonEntry pokemon;
  final int count;

  const _PokedexCard({required this.pokemon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: pokemon.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pokemon.color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PokemonImage(pokemon: pokemon, size: 72),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  pokemon.katakana,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pokemon.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                pokemon.hiragana,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // 複数回ゲットしたときのバッジ
        if (count > 1)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.pinkAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '×$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── なぞりヒントボタン ────────────────────────────────────────────────────────

class _HintButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool active;

  const _HintButton({required this.onPressed, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFFE082).withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFFFA000) : const Color(0xFFCCCCCC),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: active ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                'ヒント',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? const Color(0xFFFFA000)
                      : AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── コンフェッティ（キラキラエフェクト） ──────────────────────────────────────

class _Particle {
  final double startX;
  final double speed;
  final double wobble;
  final double rotation;
  final double size;
  final Color color;
  final bool isRect;

  const _Particle({
    required this.startX,
    required this.speed,
    required this.wobble,
    required this.rotation,
    required this.size,
    required this.color,
    required this.isRect,
  });
}

class _ConfettiOverlay extends StatefulWidget {
  final Color baseColor;

  const _ConfettiOverlay({required this.baseColor});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _random = math.Random();

  static const _palette = [
    Color(0xFFFFD700),
    Color(0xFFFF69B4),
    Color(0xFF00CED1),
    Color(0xFF98FB98),
    Color(0xFFFF6347),
    Color(0xFFDDA0DD),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..forward();

    final colors = [..._palette, widget.baseColor];
    _particles = List.generate(60, (_) {
      return _Particle(
        startX: _random.nextDouble(),
        speed: 0.6 + _random.nextDouble() * 0.6,
        wobble: (_random.nextDouble() - 0.5) * 2,
        rotation: _random.nextDouble() * math.pi * 2,
        size: 6 + _random.nextDouble() * 10,
        color: colors[_random.nextInt(colors.length)],
        isRect: _random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _ctrl.value,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final alpha =
          progress < 0.75 ? 1.0 : 1.0 - ((progress - 0.75) / 0.25);
      paint.color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0));

      final y = size.height * progress * p.speed - p.size;
      final x = size.width * p.startX +
          math.sin(progress * math.pi * 4 + p.wobble * math.pi) * 30;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + progress * math.pi * 4 * p.speed);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
