import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project1/services/picked_media_filter.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('picked_media_filter_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  File make(String name, {required int bytes}) {
    final f = File('${tmp.path}/$name')..createSync();
    if (bytes > 0) f.writeAsBytesSync(List<int>.filled(bytes, 0x41));
    return f;
  }

  test('0바이트 파일은 뺀다 — 동기화가 덜 끝난 사진이 이렇게 온다', () async {
    final ok = make('ok.jpg', bytes: 10);
    final empty = make('empty.jpg', bytes: 0);

    var skipped = 0;
    final kept = await PickedMediaFilter.usable([ok, empty],
        onSkipped: (n) => skipped = n);

    expect(kept.map((e) => e.path), [ok.path]);
    expect(skipped, 1);
  });

  test('없는 파일은 뺀다 — OS 가 임시 파일을 지웠을 수 있다', () async {
    final ok = make('ok.jpg', bytes: 10);
    final gone = File('${tmp.path}/gone.jpg'); // 만들지 않는다

    var skipped = 0;
    final kept = await PickedMediaFilter.usable([ok, gone],
        onSkipped: (n) => skipped = n);

    expect(kept.map((e) => e.path), [ok.path]);
    expect(skipped, 1);
  });

  test('멀쩡한 것만 있으면 순서를 그대로 두고 안내도 하지 않는다', () async {
    final a = make('a.jpg', bytes: 3);
    final b = make('b.jpg', bytes: 5);

    var called = false;
    final kept =
        await PickedMediaFilter.usable([a, b], onSkipped: (_) => called = true);

    expect(kept.map((e) => e.path), [a.path, b.path]);
    expect(called, isFalse, reason: '뺀 게 없으면 알리지 않는다');
  });

  test('큰 파일은 빼지 않는다 — 크기 상한을 두지 않기로 했다', () async {
    // 모모앨범에서 Cloudflare 에 직접 올려 확인했더니 9·11·15MB 가 모두
    // 통과했다(2026-09-20). 근거 없는 상한으로 멀쩡한 사진을 거절하면 안 된다.
    final big = make('big.jpg', bytes: 3 * 1024 * 1024);

    final kept = await PickedMediaFilter.usable([big]);
    expect(kept.map((e) => e.path), [big.path]);
  });
}
