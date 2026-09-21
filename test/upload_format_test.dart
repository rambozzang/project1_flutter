import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project1/repo/cloudflare/direct_upload_repo.dart';

/// 업로드 전에 **폰에서 포맷을 바꾸지 않는다**는 것을 못 박는 테스트.
///
/// 예전에는 heic/heif 를 png 로 바꿔 올렸다. png 는 무손실이라 12MP 아이폰
/// 사진이 20~35MB 로 불어나 변환·데이터·업로드가 전부 열 배가 됐다. Cloudflare
/// Images 는 heic 를 원본으로 받고(모모앨범 2026-09-09 운영 실측) 변환은 그쪽이
/// 한다 — 그래서 우리는 손대지 않는다.
///
/// 누가 "아이폰 사진이 안 열린다"며 변환을 되살리면 여기서 걸린다.
void main() {
  late Directory tmp;
  final repo = DirectUploadRepo();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('upload_format_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  File write(String name, List<int> bytes) {
    final f = File('${tmp.path}/$name');
    f.writeAsBytesSync(bytes);
    return f;
  }

  /// ISO-BMFF: 길이 4바이트 + 'ftyp' + 브랜드.
  List<int> heicBytes() => [
        0, 0, 0, 0x18,
        ...'ftyp'.codeUnits,
        ...'heic'.codeUnits,
        ...List<int>.filled(40, 0),
      ];

  test('heic 는 그대로 올린다 — png 로 바꾸지 않는다', () async {
    final src = write('photo.heic', heicBytes());
    final out = await repo.prepareForUpload(src);
    expect(out.path, src.path, reason: '경로가 바뀌면 변환이 되살아난 것이다');
  });

  test('확장자가 jpg 여도 내용이 heic 면 그대로 올린다', () async {
    // 갤러리가 주는 확장자는 믿을 게 못 된다. 시그니처로 판정해야 한다.
    final src = write('mislabeled.jpg', heicBytes());
    final out = await repo.prepareForUpload(src);
    expect(out.path, src.path);
  });

  test('jpeg·png·gif·webp 도 손대지 않는다', () async {
    final files = <File>[
      write('a.jpg', [0xFF, 0xD8, 0xFF, ...List<int>.filled(60, 0)]),
      write('b.png', [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        ...List<int>.filled(56, 0),
      ]),
      // gif 는 jpeg 로 바꾸면 움직임이 사라진다 — 반드시 원본이어야 한다.
      write('c.gif', [...'GIF89a'.codeUnits, ...List<int>.filled(58, 0)]),
      write('d.webp', [
        ...'RIFF'.codeUnits,
        0, 0, 0, 0,
        ...'WEBP'.codeUnits,
        ...List<int>.filled(52, 0),
      ]),
    ];
    for (final f in files) {
      expect((await repo.prepareForUpload(f)).path, f.path, reason: f.path);
    }
  });

  test('받아주지 않는 포맷도 원본을 그대로 돌려준다(서버 판정에 맡긴다)', () async {
    // bmp. 변환기를 두지 않기로 했으므로 경로가 바뀌면 안 된다.
    final src = write('e.bmp', [0x42, 0x4D, ...List<int>.filled(62, 0)]);
    expect((await repo.prepareForUpload(src)).path, src.path);
  });

  test('파일을 읽지 못해도 던지지 않는다 — 업로드를 막으면 안 된다', () async {
    final missing = File('${tmp.path}/nope.jpg');
    expect((await repo.prepareForUpload(missing)).path, missing.path);
  });
}
