export 'download_stub.dart'
    if (dart.library.js_interop) 'download_web.dart'
    if (dart.library.io) 'download_mobile.dart';
