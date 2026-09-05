import 'package:flutter_test/flutter_test.dart';
import 'package:project1/app/videolist/video_decoder_window.dart';

void main() {
  group('isVideoActive', () {
    test('현재 영상은 항상 활성', () {
      expect(isVideoActive(videoIndex: 7, currentVideoIndex: 7), isTrue);
    });

    test('앞뒤 3장까지 활성', () {
      expect(isVideoActive(videoIndex: 4, currentVideoIndex: 7), isTrue);
      expect(isVideoActive(videoIndex: 10, currentVideoIndex: 7), isTrue);
    });

    test('4장 이상 떨어지면 비활성 — 디코더를 놓는다', () {
      expect(isVideoActive(videoIndex: 3, currentVideoIndex: 7), isFalse);
      expect(isVideoActive(videoIndex: 11, currentVideoIndex: 7), isFalse);
      expect(isVideoActive(videoIndex: 0, currentVideoIndex: 7), isFalse);
    });

    test('피드 첫 진입(0번)에서도 앞쪽 3장이 활성', () {
      expect(isVideoActive(videoIndex: 0, currentVideoIndex: 0), isTrue);
      expect(isVideoActive(videoIndex: 3, currentVideoIndex: 0), isTrue);
      expect(isVideoActive(videoIndex: 4, currentVideoIndex: 0), isFalse);
    });

    test('동시 활성 개수는 최대 7개 — preloadPagesCount=5(11장)보다 적어야 의미가 있다', () {
      const current = 20;
      final active = List.generate(40, (i) => i)
          .where((i) => isVideoActive(videoIndex: i, currentVideoIndex: current))
          .length;
      expect(active, 7);
    });
  });

  group('videoWindowSize', () {
    // 모모앨범(album_immersive_page.dart의 _videoWindow)과 동일한 값이어야 한다.
    test('윈도우는 프리로드 페이지 수보다 작아야 한다 — 같으면 줄이는 의미가 없다', () {
      expect(kVideoWindow, lessThan(5));
    });

    test('모모앨범과 동일한 대칭 3장', () {
      expect(kVideoWindow, 3);
    });
  });
}
