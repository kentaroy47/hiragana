/// モバイル・デスクトップ用スタブ（何もしない）
class SoundService {
  static bool _bgmPlaying = false;
  static bool get bgmPlaying => _bgmPlaying;

  static void playStrokeComplete() {}
  static void playCatch() {}

  static void toggleBgm() {
    _bgmPlaying = !_bgmPlaying;
  }
}
