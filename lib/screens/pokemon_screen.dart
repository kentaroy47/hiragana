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
  int _caughtCount = 0;
  bool _advancing = false;
  int _sessionId = 0; // ValueKey 用：変わると DrawingCanvas が新規作成される

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
          _caughtCount++;
          _showCatchOverlay = true;
          _advancing = false;
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
              caughtCount: _caughtCount,
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
                      // ふりがな
                      Text(
                        _pokemon.hiragana,
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppTheme.textGray,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // お絵かきキャンバス
                      Expanded(
                        child: DrawingCanvas(
                          key: ValueKey('$_sessionId-$_charIndex'),
                          character: currentChar,
                          totalStrokes: strokeCount,
                          onComplete: _onCharComplete,
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
                    onNext: _pickNewPokemon,
                    onRetry: _retrySamePokemon,
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
  final int caughtCount;
  final VoidCallback onBack;

  const _LeftPanel({
    required this.pokemon,
    required this.caughtCount,
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

          // ゲット数
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'ゲット：$caughtCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
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
  final VoidCallback onNext;
  final VoidCallback onRetry;

  const _CatchOverlay({
    required this.pokemon,
    required this.scores,
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
