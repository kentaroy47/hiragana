// Web では Web Audio API を使用、モバイル等ではスタブを使用
export 'sound_service_stub.dart'
    if (dart.library.js) 'sound_service_web.dart';
