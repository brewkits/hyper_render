import 'file_helper_interface.dart';
import 'file_helper_io.dart'
    if (dart.library.js_interop) 'file_helper_web.dart'
    if (dart.library.html) 'file_helper_web.dart';

export 'file_helper_interface.dart';

/// Default platform file helper instance.
PlatformFileHelper getPlatformFileHelper() => const PlatformFileHelperImpl();
