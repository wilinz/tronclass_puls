import 'dart:io';

import 'package:path_provider/path_provider.dart';

late final Directory applicationSupportDirectory;

Future<void> initFilePath() async {
  applicationSupportDirectory = await getApplicationSupportDirectory();
}