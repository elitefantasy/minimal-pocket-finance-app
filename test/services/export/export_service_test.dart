import 'dart:io';

import 'package:akm_finance_manager/services/export/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('akm_export_');
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('exports the file under the application Database folder', () async {
    final source = File(path.join(temporaryDirectory.path, 'finance.db'));
    await source.writeAsString('database');
    final downloads = Directory(
      path.join(temporaryDirectory.path, 'Downloads'),
    );
    final service = ExportService(
      destinationResolver: _FakeDestinationResolver(downloads),
    );

    final exportedPath = await service.exportFile(
      sourcePath: source.path,
      artifactFolder: 'Database',
    );

    expect(
      exportedPath,
      path.join(
        downloads.absolute.path,
        'AKM Finance Manager',
        'Database',
        'finance.db',
      ),
    );
    expect(await File(exportedPath).readAsString(), 'database');
  });

  test('throws a meaningful exception when the source is missing', () async {
    final service = ExportService(
      destinationResolver: _FakeDestinationResolver(temporaryDirectory),
    );

    expect(
      () => service.exportFile(
        sourcePath: path.join(temporaryDirectory.path, 'missing.db'),
        artifactFolder: 'Database',
      ),
      throwsA(isA<ExportException>()),
    );
  });
}

class _FakeDestinationResolver implements ExportDestinationResolver {
  const _FakeDestinationResolver(this.directory);

  final Directory directory;

  @override
  Future<Directory> getDownloadsDirectory() async => directory;
}
