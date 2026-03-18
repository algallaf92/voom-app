/// Stub implementation of deepar_flutter for CI builds.
/// This package replaces the real deepar_flutter when building without the
/// proprietary DeepAR SDK (e.g. in GitHub Actions CI).
library deepar_flutter;

import 'package:flutter/widgets.dart';

/// Stub controller — all methods are no-ops.
class DeepArController {
  Future<void> initialize({
    String androidLicenseKey = '',
    String iosLicenseKey = '',
  }) async {}

  Future<void> switchEffect(String path) async {}

  Future<void> destroy() async {}
}

/// Stub preview widget — renders an empty box.
class DeepArPreview extends StatelessWidget {
  final DeepArController controller;

  const DeepArPreview(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
