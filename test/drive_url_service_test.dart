import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/drive_url_service.dart';

void main() {
  test('extracts file id from common Google Drive formats', () {
    expect(
      DriveUrlService.extractFileId(
        'https://drive.google.com/file/d/ABC123xyz/view?usp=sharing',
      ),
      'ABC123xyz',
    );

    expect(
      DriveUrlService.extractFileId(
        'https://drive.google.com/open?id=ABC123xyz',
      ),
      'ABC123xyz',
    );

    expect(
      DriveUrlService.extractFileId(
        'https://drive.google.com/uc?export=view&id=ABC123xyz',
      ),
      'ABC123xyz',
    );
  });

  test('builds a direct PDF download URL from collected drive links', () {
    expect(
      DriveUrlService.buildDirectDownloadUrl(
        'https://drive.google.com/open?id=ABC123xyz',
      ),
      'https://drive.google.com/uc?export=download&id=ABC123xyz&confirm=t',
    );
  });
}
