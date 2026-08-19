import 'package:flutter_test/flutter_test.dart';
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
      await exportPreferences.saveExportRootUri('/custom/export/path');
      final path = await exportPreferences.getExportRootUri();
      final isSet = await exportPreferences.isCustomExportFolderSet();

      expect(path, equals('/custom/export/path'));
      expect(isSet, isTrue);
    });

    test('clearExportRootUri resets custom export folder', () async {
      await exportPreferences.saveExportRootUri('/custom/export/path');
      await exportPreferences.clearExportRootUri();

      final path = await exportPreferences.getExportRootUri();
      final isSet = await exportPreferences.isCustomExportFolderSet();

      expect(path, isNull);
      expect(isSet, isFalse);
    });
  });
}
