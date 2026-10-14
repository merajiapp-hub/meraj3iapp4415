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

  test('preserves Google Drive resource keys across reader URLs', () {
    const url =
        'https://drive.google.com/file/d/ABC123xyz/view?resourcekey=key123';

    expect(
      DriveUrlService.buildPreviewUrl(url),
      'https://drive.google.com/file/d/ABC123xyz/view?usp=sharing&resourcekey=key123',
    );
    expect(
      DriveUrlService.buildDirectDownloadUrl(url),
      'https://drive.google.com/uc?export=download&id=ABC123xyz&confirm=t&resourcekey=key123',
    );
  });

  test('builds an embedded preview URL and preserves a Drive resource key', () {
    expect(
      DriveUrlService.buildEmbedUrl(
        'https://drive.google.com/file/d/ABC123xyz/view?resourcekey=key123',
      ),
      'https://drive.google.com/file/d/ABC123xyz/preview?resourcekey=key123',
    );
    expect(
      DriveUrlService.buildEmbedUrl(
        'https://drive.google.com/open?id=ABC123xyz',
      ),
      'https://drive.google.com/file/d/ABC123xyz/preview',
    );
  });

  test('does not rewrite non-Drive URLs as embedded Drive previews', () {
    const url = 'https://example.com/books/ABC123xyz.pdf';

    expect(DriveUrlService.buildEmbedUrl(url), url);
    expect(DriveUrlService.buildPreviewUrl(url), url);
    expect(DriveUrlService.buildDirectDownloadUrl(url), url);
    expect(
      DriveUrlService.buildEmbedUrl(
        'https://example.com/file/d/ABC123xyz/view',
      ),
      'https://example.com/file/d/ABC123xyz/view',
    );
  });

  test('does not convert Drive folder links into PDF file links', () {
    const url = 'https://drive.google.com/drive/folders/FOLDER123';

    expect(DriveUrlService.buildEmbedUrl(url), url);
    expect(DriveUrlService.buildPreviewUrl(url), url);
    expect(DriveUrlService.buildDirectDownloadUrl(url), url);
    expect(DriveUrlService.buildWebOpenUrl(url), url);
  });

  test('does not accept a host that only contains a Google Drive hostname', () {
    const url = 'https://drive.google.com.evil.example/file/d/ABC123xyz/view';

    expect(DriveUrlService.isDriveUrl(url), isFalse);
    expect(DriveUrlService.buildEmbedUrl(url), url);
  });
}
