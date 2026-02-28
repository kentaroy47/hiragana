import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

/// Web Audio API を使った効果音・BGM サービス
class SoundService {
  static bool _bgmPlaying = false;
  static bool get bgmPlaying => _bgmPlaying;

  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    _jsEval('''
      window._getAudioCtx = function() {
        try {
          window._audioCtx = window._audioCtx ||
              new (window.AudioContext || window.webkitAudioContext)();
          if (window._audioCtx.state === 'suspended') window._audioCtx.resume();
          return window._audioCtx;
        } catch(e) { return null; }
      };
    ''');
  }

  static void _eval(String code) {
    _init();
    try {
      _jsEval(code);
    } catch (_) {}
  }

  /// 1文字なぞり完了音（ポーン）
  static void playStrokeComplete() {
    _eval('''
      (function() {
        var ctx = _getAudioCtx(); if (!ctx) return;
        var t = ctx.currentTime;
        [523.25, 659.25].forEach(function(f, i) {
          var osc = ctx.createOscillator(), g = ctx.createGain();
          osc.connect(g); g.connect(ctx.destination);
          osc.frequency.value = f; osc.type = 'sine';
          g.gain.setValueAtTime(0.25, t + i * 0.13);
          g.gain.exponentialRampToValueAtTime(0.001, t + i * 0.13 + 0.18);
          osc.start(t + i * 0.13); osc.stop(t + i * 0.13 + 0.18);
        });
      })();
    ''');
  }

  /// ポケモンゲット音（上昇メロディ）
  static void playCatch() {
    _eval('''
      (function() {
        var ctx = _getAudioCtx(); if (!ctx) return;
        var t = ctx.currentTime;
        var notes = [392, 523.25, 659.25, 783.99];
        notes.forEach(function(f, i) {
          var osc = ctx.createOscillator(), g = ctx.createGain();
          osc.connect(g); g.connect(ctx.destination);
          osc.frequency.value = f; osc.type = 'sine';
          var st = t + i * 0.16;
          var dur = i === notes.length - 1 ? 0.55 : 0.16;
          g.gain.setValueAtTime(0.35, st);
          g.gain.exponentialRampToValueAtTime(0.001, st + dur);
          osc.start(st); osc.stop(st + dur);
        });
      })();
    ''');
  }

  static void toggleBgm() {
    if (_bgmPlaying) {
      _stopBgm();
    } else {
      _startBgm();
    }
    _bgmPlaying = !_bgmPlaying;
  }

  static void _startBgm() {
    _eval('''
      (function() {
        var ctx = _getAudioCtx(); if (!ctx) return;
        window._bgmActive = true;
        var melody = [523, 659, 784, 659, 523, 587, 784, 880,
                      784, 659, 523, 659, 587, 523, 392, 523];
        var i = 0;
        function playNote() {
          if (!window._bgmActive) return;
          var osc = ctx.createOscillator(), g = ctx.createGain();
          osc.connect(g); g.connect(ctx.destination);
          osc.frequency.value = melody[i % melody.length];
          osc.type = 'square';
          g.gain.setValueAtTime(0.06, ctx.currentTime);
          g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.32);
          osc.start(ctx.currentTime); osc.stop(ctx.currentTime + 0.32);
          i++;
          window._bgmTimer = setTimeout(playNote, 340);
        }
        playNote();
      })();
    ''');
  }

  static void _stopBgm() {
    _eval('''
      (function() {
        window._bgmActive = false;
        if (window._bgmTimer) clearTimeout(window._bgmTimer);
      })();
    ''');
  }
}
