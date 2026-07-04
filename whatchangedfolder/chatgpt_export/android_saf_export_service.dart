import 'dart:io';

import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import 'package:akm_finance_manager/services/export/android_export_location_service.dart';

/// Handles Android exports using the Storage Access Framework.
class AndroidSafExportService {
  AndroidSafExportService({
    AndroidExportLocationService? locationService,
    SafUtil? safUtil,
    SafStream? safStream,
  })  : _locationService =
            locationService ?? AndroidExportLocationService(),
        _safUtil = safUtil ?? SafUtil(),
        _safStream = safStream ?? SafStream();

  // Gets the folder selected by the user.
  final AndroidExportLocationService _locationService;

  // Creates folders inside the selected location.
  final SafUtil _safUtil;

  // Writes files into SAF.
  final SafStream _safStream;
}