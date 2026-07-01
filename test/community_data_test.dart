import 'package:flutter_test/flutter_test.dart';
import 'package:project1/repo/community/data/community_data.dart';

// CommunityData.fromMap 의 boolean(owner/manager) 파싱 회귀 방지 테스트.
// 백엔드(Lombok @Getter + Jackson)는 isOwner()→'owner', isManager()→'manager' 로 직렬화하므로
// is-prefix 를 제거한 키까지 fallback 체인에 포함돼야 한다.
void main() {
  group('CommunityData.fromMap boolean 파싱', () {
    test('manager 키(Jackson 직렬화)로 isManager=true', () {
      final data = CommunityData.fromMap({'communityId': 1, 'manager': true});
      expect(data.isManager, isTrue);
      expect(data.canEditCover, isTrue);
    });

    test('isManager 키로도 isManager=true', () {
      final data = CommunityData.fromMap({'communityId': 1, 'isManager': true});
      expect(data.isManager, isTrue);
    });

    test('owner 키(Jackson 직렬화)로 isOwner=true, 방장은 매니저로 취급', () {
      final data = CommunityData.fromMap({'communityId': 1, 'owner': true});
      expect(data.isOwner, isTrue);
      expect(data.isManager, isTrue); // 방장 fallback
      expect(data.canEditCover, isTrue);
    });

    test('isOwner 키로도 isOwner=true', () {
      final data = CommunityData.fromMap({'communityId': 1, 'isOwner': true});
      expect(data.isOwner, isTrue);
    });

    test('플래그가 없으면 모두 false', () {
      final data = CommunityData.fromMap({'communityId': 1});
      expect(data.isOwner, isFalse);
      expect(data.isManager, isFalse);
      expect(data.canEditCover, isFalse);
    });

    test('coverTemplateId 파싱', () {
      final data = CommunityData.fromMap({'communityId': 1, 'coverTemplateId': 'night_sky'});
      expect(data.coverTemplateId, 'night_sky');

      final none = CommunityData.fromMap({'communityId': 1});
      expect(none.coverTemplateId, isNull);
    });
  });
}
