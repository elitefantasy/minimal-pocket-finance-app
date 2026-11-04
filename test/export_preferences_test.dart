import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_pocket_finance_app/services/export/android_export_location_service.dart';
import 'package:minimal_pocket_finance_app/services/export/android_saf_export_service.dart';
import 'package:minimal_pocket_finance_app/services/export/export_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportPreferences tests', () {
    late ExportPreferences exportPreferences;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      exportPreferences = ExportPreferences();
    });

    test('isCustomExportFolderSet returns false initially', () async {
      final isSet = await exportPreferences.isCustomExportFolderSet();
      expect(isSet, isFalse);
    });

    test('saveExportRootUri stores uri and isCustomExportFolderSet returns true', () async {
      await exportPreferences.saveExportRootUri('content://com.android.externalstorage.documents/tree/primary%3ADownload');
      final path = await exportPreferences.getExportRootUri();
      final isSet = await exportPreferences.isCustomExportFolderSet();

      expect(path, equals('content://com.android.externalstorage.documents/tree/primary%3ADownload'));
      expect(isSet, isTrue);
    });

    test('clearExportRootUri resets custom export folder', () async {
      await exportPreferences.saveExportRootUri('content://com.android.externalstorage.documents/tree/primary%3ADownload');
      await exportPreferences.clearExportRootUri();

      final path = await exportPreferences.getExportRootUri();
      final isSet = await exportPreferences.isCustomExportFolderSet();

      expect(path, isNull);
      expect(isSet, isFalse);
    });
  });

  group('AndroidExportLocationService self-healing tests', () {
    late ExportPreferences preferences;
    late AndroidExportLocationService locationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      preferences = ExportPreferences();
      locationService = AndroidExportLocationService(preferences: preferences);
    });

    test('clears corrupted "/" path and returns null safely', () async {
      // Simulate corrupted "/" stored in SharedPreferences
      await preferences.saveExportRootUri('/');

      final savedUri = await locationService.getSavedUri();
      expect(savedUri, isNull);

      // Verify that preferences was cleaned up
      final inPrefs = await preferences.getExportRootUri();
      expect(inPrefs, isNull);
    });

    test('clears invalid POSIX path and returns null safely', () async {
      await preferences.saveExportRootUri('/storage/emulated/0/Download');

      final savedUri = await locationService.getSavedUri();
      expect(savedUri, isNull);

      final inPrefs = await preferences.getExportRootUri();
      expect(inPrefs, isNull);
    });

    test('retains valid content:// SAF URI', () async {
      const validSafUri =
          'content://com.android.externalstorage.documents/tree/primary%3ADownload%2FFinance';
      await preferences.saveExportRootUri(validSafUri);

      final savedUri = await locationService.getSavedUri();
      expect(savedUri, equals(validSafUri));
    });
  });

  group('AndroidSafExportService.resolveDisplayPath tests', () {
    test('resolves primary download tree URI', () {
      const safUri =
          'content://com.android.externalstorage.documents/tree/primary%3ADownload';
      final path = AndroidSafExportService.resolveDisplayPath(safUri);
      expect(path, equals('/storage/emulated/0/Download'));
    });

    test('resolves primary subfolder with filename', () {
      const safUri =
          'content://com.android.externalstorage.documents/tree/primary%3ADocuments%2FFinance';
      final path = AndroidSafExportService.resolveDisplayPath(safUri, 'backup.db');
      expect(path, equals('/storage/emulated/0/Documents/Finance/backup.db'));
    });

    test('resolves primary root', () {
      const safUri =
          'content://com.android.externalstorage.documents/tree/primary%3A';
      final path = AndroidSafExportService.resolveDisplayPath(safUri);
      expect(path, equals('/storage/emulated/0'));
    });
  });
}
