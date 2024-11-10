import 'dart:math';

import 'package:flutter/material.dart';

// Anonymous Profile 클래스 정의
class AnonymousProfile {
  final String nickname;
  final String avatarUrl;

  AnonymousProfile({
    required this.nickname,
    required this.avatarUrl,
  });

  // toString 메서드 오버라이드 (디버깅용)
  @override
  String toString() => 'AnonymousProfile(nickname: $nickname, avatarUrl: $avatarUrl)';
}

class AnonymousProfileGenerator {
  // 형용사 목록 확장
  static final List<String> _adjectives = [
    // 감정/성격
    '즐거운', '행복한', '신나는', '귀여운', '멋진', '차분한', '열정적인', '친절한',
    '우아한', '당당한', '은은한', '화려한', '수줍은', '당찬', '엉뚱한', '나이스',
    '섹시한', '근엄한', '유쾌한', '똑똑한', '무뚝뚝한',

    // 상태/분위기
    '몽환적인', '신비로운', '낭만적인', '청량한', '포근한', '달콤한', '시크한',
    '힙한', '감성적인', '트렌디한', '빈티지한', '모던한', '키치한', '날으는',
    '빛나는', '무한한', '빠른', '느린', '끝없는', '끝나는',
    '끝나는', '끝나지 않는', '끝나는', '끝나지 않는', '끝나는',

    // 계절/자연
    '봄날의', '여름의', '가을의', '겨울의', '숲속의', '바다의', '하늘의',
    '달빛의', '별빛의', '새벽의', '노을의', '무지개의', '바람의', '비의',
    '눈의', '얼음의', '불의', '빛의', '어둠의', '밤의', '낮의',
  ];

  // 명사 목록 확장
  static final List<String> _nouns = [
    // 한국 아이스ㅡ림 이름
    '바나나우유', '초코우유', '딸기우유', '바닐라우유', '커피우유', '녹차우유',

    // 한국 아이스크림 이름
    '메로나', '빵빠레', '죠스바', '누가바', '폴라포', '뽕따', '쿠앤크',

    // 한국 유명 유튜버 이름
    '쯔양', '백종원', '허팝', '빠니보틀', '곽튜브',

    // 한국 개그맨 별명
    '유민상', '박명수', '노홍철', '정형돈', '정준하', '김구라', '김숙',

    // 동물
    '판다', '고양이', '강아지', '토끼', '여우', '사자', '기린',
    '코끼리', '펭귄', '곰', '돌고래', '호랑이', '햄스터', '다람쥐',
    '앵무새', '거북이', '페럿', '오리', '말', '코뿔소', '캥거루',

    // 음식
    '마카롱', '아이스크림', '케이크', '쿠키', '타르트', '푸딩', '와플',
    '도넛', '크로플', '마들렌', '커피', '크로와상',

    // 자연/우주
    '은하수', '별똥별', '무지개', '구름', '오로라', '나비', '달빛',
    '새싹', '꽃잎', '단풍잎', '벚꽃', '바람',

    // 판타지
    '마법사', '요정', '드래곤', '유니콘', '정령', '피닉스', '인어',
    '엘프', '페가수스',

    //연예인 이름
    '아이유', '방탄소년단', '트와이스', '블랙핑크', '레드벨벳', '엑소', '워너원',
    '아이즈원', '세븐틴', '뉴이스트', '비투비', '빅뱅', '마마무',
    '에이핑크', '오마이걸', '우주소녀', '모모랜드', '아스트로',

    // 만화 주인공
    '나루토', '루피', '에드워드 엘릭', '나츠', '가츠', '에이스', '토르',
    '아이언맨', '헐크', '블랙위도우', '토르',
    '헬로키티', '미키마우스', '도라에몽',

    // 영화 주인공
    '해리포터',
    '헤르미온느',
    '론',
    '말포이',
    '덤블도어',
    '헤르미온느'
        '아이언맨',
    '헐크',
    '토르',

    '도깨비',
  ];

  // 감탄사/접두어
  static final List<String> _prefixes = [
    '어머',
    '아차',
    '앗',
    '어라',
    '으랏',
    '웨않',
    '엥',
    '헉',
    '후욱',
    '앗뇽',
    '어쩜',
    '어맛',
    '어이쿠',
  ];

  // 이모지 세트
  static final List<String> _emojis = [
    '✨',
    '🌟',
    '💫',
    '⭐️',
    '🌙',
    '☁️',
    '🌈',
    '🍀',
    '🌸',
    '🌺',
    '🌷',
    '🌹',
    '🌻',
    '🍓',
    '🍎',
    '🍒',
    '🎨',
    '🎭',
    '🎪',
    '🎡',
    '🎢',
    '🎵',
    '🎶',
    '💝',
  ];

  // 특별한 단어/구절
  static final List<String> _specialPhrases = [
    '낮잠자는',
    '꿈꾸는',
    '춤추는',
    '노래하는',
    '공부하는',
    '요리하는',
    '여행하는',
    '독서하는',
    '명상하는',
    '그림그리는',
    '사진찍는',
  ];

  // 닉네임 패턴 생성 함수들
  static String _generateBasicPattern() {
    final random = Random();
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    return '$adjective $noun';
  }

  static String _generateEmojiPattern() {
    final random = Random();
    final noun = _nouns[random.nextInt(_nouns.length)];
    final emoji = _emojis[random.nextInt(_emojis.length)];
    return '$emoji$noun$emoji';
  }

  static String _generateSpecialPattern() {
    final random = Random();
    final phrase = _specialPhrases[random.nextInt(_specialPhrases.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    return '$phrase $noun';
  }

  static String _generatePrefixPattern() {
    final random = Random();
    final prefix = _prefixes[random.nextInt(_prefixes.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    final emoji = _emojis[random.nextInt(_emojis.length)];
    return '$emoji$prefix $noun';
  }

  static String _generateCompositePattern() {
    final random = Random();
    final adj1 = _adjectives[random.nextInt(_adjectives.length)];
    final adj2 = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    return '$adj1$adj2 $noun';
  }

  // 랜덤 닉네임 생성
  static String generateNickname() {
    final random = Random();
    final patterns = [
      _generateBasicPattern,
      _generateEmojiPattern,
      // _generateSpecialPattern,
      _generatePrefixPattern,
      // _generateCompositePattern,
    ];

    final selectedPattern = patterns[random.nextInt(patterns.length)];
    return selectedPattern();
  }

  // 특정 테마에 따른 닉네임 생성
  static String generateThemedNickname(String theme) {
    switch (theme.toLowerCase()) {
      case 'cute':
        return '${_emojis[Random().nextInt(_emojis.length)]} ${_generateBasicPattern()}';
      case 'fantasy':
        final fantasyAdj = ['신비로운', '마법의', '환상의', '전설의', '신성한'][Random().nextInt(5)];
        return '$fantasyAdj ${_nouns[Random().nextInt(_nouns.length)]}';
      case 'food':
        final foodAdj = ['맛있는', '달콤한', '향긋한', '쫄깃한', '바삭한'][Random().nextInt(5)];
        final foodEmoji = ['🍰', '🍪', '🍩', '🍫', '🍮'][Random().nextInt(5)];
        return '$foodEmoji $foodAdj ${_nouns[Random().nextInt(_nouns.length)]}';
      default:
        return generateNickname();
    }
  }

  static String generateAvatarUrl({int size = 200}) {
    final List<String> styles = ['avataaars', 'bottts', 'adventurer', 'fun-emoji', 'thumbs'];

    final random = Random();
    final style = styles[random.nextInt(styles.length)];
    final seed = DateTime.now().millisecondsSinceEpoch.toString();

    return 'https://api.dicebear.com/7.x/$style/svg?seed=$seed&size=$size';
  }

  static AnonymousProfile generateProfile({bool useInitials = false, String? theme}) {
    final nickname = theme != null ? generateThemedNickname(theme) : generateNickname();
    final avatarUrl = generateAvatarUrl();

    return AnonymousProfile(nickname: nickname, avatarUrl: avatarUrl);
  }
}
