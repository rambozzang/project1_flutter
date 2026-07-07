import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/utils/log_utils.dart';

/// 앨범(커뮤니티) 초대 딥링크 처리 서비스.
///
/// 지원 형태:
/// - 커스텀 스킴: skysnap://invite?code=XXX
/// - App Links(Universal Links): https://skysnap.co.kr/invite?code=XXX
///
/// 로그인이 안 된 상태로 링크를 타고 들어온 경우, code를 임시 보관해두었다가
/// 로그인이 완료되는 시점(AuthCntr.isLogged)에 이어서 가입 처리를 진행한다.
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final CommunityRepo _communityRepo = CommunityRepo();

  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingInviteCode;
  bool _processing = false;

  /// main()에서 앱 시작 시 1회 호출. 콜드스타트 초기 링크 + 이후 스트림을 함께 수신한다.
  Future<void> initialize() async {
    // 로그인 완료 시점에 대기 중인 초대 코드가 있으면 이어서 처리.
    ever(AuthCntr.to.isLogged, (isLogged) {
      if (isLogged == true) {
        _consumePendingInviteCode();
      }
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      lo.g('DeepLinkService.initialize getInitialLink error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) => lo.g('DeepLinkService uriLinkStream error: $e'),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  void _handleUri(Uri uri) {
    lo.g('DeepLinkService 수신 uri: $uri');

    // 커스텀 스킴: skysnap://invite?code=XXX 또는 skysnap://invite/XXX
    // App Links: https://skysnap.co.kr/invite?code=XXX 또는 /invite/XXX
    // ※ 실제 공유 링크·QR(album_invite_page._inviteLink)은 경로형(/invite/{code})이다 —
    //   쿼리(?code=)만 읽으면 링크·QR 유입이 전부 조용히 무시되던 버그가 있었음.
    final isCustomSchemeInvite = uri.scheme == 'skysnap' && uri.host == 'invite';
    final isAppLinkInvite = (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'skysnap.co.kr' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'invite';

    if (!isCustomSchemeInvite && !isAppLinkInvite) return;

    String? code = uri.queryParameters['code'];
    if ((code == null || code.trim().isEmpty) && isAppLinkInvite && uri.pathSegments.length >= 2) {
      code = uri.pathSegments[1]; // https://skysnap.co.kr/invite/{code}
    }
    if ((code == null || code.trim().isEmpty) && isCustomSchemeInvite && uri.pathSegments.isNotEmpty) {
      code = uri.pathSegments.first; // skysnap://invite/{code}
    }
    if (code == null || code.trim().isEmpty) return;

    _pendingInviteCode = code.trim();
    _consumePendingInviteCode();
  }

  void _consumePendingInviteCode() {
    final code = _pendingInviteCode;
    if (code == null || code.isEmpty) return;
    if (!AuthCntr.to.isLogged.value) return; // 로그인 완료 전이면 대기 유지(로그인 후 ever에서 재시도).
    if (_processing) return;

    _pendingInviteCode = null;
    _processing = true;
    _joinByCode(code).whenComplete(() => _processing = false);
  }

  Future<void> _joinByCode(String code) async {
    final (ok, msg, community) = await _communityRepo.joinByCode(code);
    Get.snackbar('앨범', msg.isEmpty ? (ok ? '참여했습니다.' : '실패했습니다.') : msg,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    if (ok && community != null) {
      Get.toNamed('/CommunityHomePage', arguments: {'communityId': community.communityId});
    }
  }
}
