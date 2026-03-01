// Web では localStorage を使用、モバイル等ではスタブを使用
export 'storage_service_stub.dart'
    if (dart.library.js_interop) 'storage_service_web.dart';
