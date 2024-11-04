import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/bbs/image/image_list_preview.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'package:webviewtube/webviewtube.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MixedContent extends StatefulWidget {
  final String content;
  final double videoHeight;
  final String delYn;

  const MixedContent({
    Key? key,
    required this.content,
    this.videoHeight = 200,
    this.delYn = 'N',
  }) : super(key: key);

  @override
  State<MixedContent> createState() => _MixedContentState();
}

class _MixedContentState extends State<MixedContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<ContentPart> contentParts;
  final Map<String, WebviewtubeController> _controllers = {};
  final Map<String, ImageProvider> _imageProviders = {}; // 이미지 캐싱을 위한 맵 추가

  bool _isInitialized = false;
  bool _didInitializeImages = false; // 이미지 초기화 플래그 추가

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  void _initializeContent() {
    contentParts = MixedContentParser.parseContent(widget.content);

    // YouTube 컨트롤러 초기화
    for (var part in contentParts) {
      if (part is YoutubePart) {
        _controllers[part.videoId] = WebviewtubeController();
      } else if (part is ImagePart) {
        // 이미지 프로바이더만 초기화
        _imageProviders[part.imageUrl] = NetworkImage(part.imageUrl);
      }
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 이미지 프리로딩은 여기서 수행
    if (!_didInitializeImages) {
      for (var part in contentParts) {
        if (part is ImagePart) {
          precacheImage(_imageProviders[part.imageUrl]!, context);
        }
      }
      _didInitializeImages = true;
    }
  }

  @override
  void dispose() {
    // 모든 컨트롤러 해제
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _imageProviders.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isInitialized) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentParts.map((part) {
        if (part is TextPart) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: RichTextView(
              text: part.text,
              truncate: false,
              // viewLessText: 'less',
              style: TextStyle(color: widget.delYn == 'Y' ? Colors.grey : Colors.black, fontSize: 14, fontWeight: FontWeight.w500),
              linkStyle: const TextStyle(color: Colors.blueAccent, fontSize: 15, fontWeight: FontWeight.w600),
              selectable: true,
              supportedTypes: [
                EmailParser(onTap: (email) => print('${email.value} clicked')),
                MentionParser(
                    pattern: r'@[가-힣a-zA-Z0-9!@#$%^&*(),.?":{}|<>_-]+(?=\s|$)',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                    ),
                    onTap: (mention) => print('${mention.value} clicked')),
                UrlParser(
                  onTap: (url) => url_launcher.launchUrl(Uri.parse(url.value!)),
                ),
                BoldParser(),
                HashTagParser(onTap: (hashtag) => print('is ${hashtag.value} trending?'))
              ],
            ),
          );
        } else if (part is YoutubePart) {
          final controller = _controllers[part.videoId];
          if (controller == null) return const SizedBox();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: WebviewtubePlayer(
              videoId: part.videoId,
              controller: controller,
              options: const WebviewtubeOptions(
                forceHd: true,
                loop: false,
                showControls: false,
                interfaceLanguage: 'ko',
                captionLanguage: 'ko',
              ),
            ),
          );
        } else if (part is ImagePart) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: GestureDetector(
              onTap: () {
                // showDialog(
                //   context: context,
                //   builder: (context) => Dialog(
                //     child: InteractiveViewer(
                //       child: Image(
                //         image: _imageProviders[part.imageUrl] ?? NetworkImage(part.imageUrl),
                //       ),
                //     ),
                //   ),
                // );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageListPreview(imageUrls: [part.imageUrl]),
                  ),
                );
              },
              child: CachedNetworkImage(
                cacheKey: part.imageUrl,
                imageUrl: part.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
              // child: Image(
              //   image: _imageProviders[part.imageUrl] ?? NetworkImage(part.imageUrl),
              //   fit: BoxFit.fitHeight,
              //   errorBuilder: (context, error, stackTrace) {
              //     return const Icon(Icons.error);
              //   },
              //   loadingBuilder: (context, child, loadingProgress) {
              //     if (loadingProgress == null) return child;
              //     return const Center(
              //       child: CircularProgressIndicator(),
              //     );
              //   },
              // ),
            ),
          );
        }
        return const SizedBox();
      }).toList(),
    );
  }
}

// ContentPart 클래스들과 Parser
class MixedContentParser {
  static final RegExp _youtubeUrlPattern = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/|live\/)|youtu\.be\/)([a-zA-Z0-9_-]+)(?:\S+)?',
    caseSensitive: false,
  );

  // r'''<[Ii][Mm][Gg][^>]*?[Ss][Rr][Cc]\s*=\s*["']([^"']+?)["'][^>]*?>''',
  // r'''<[Ii][Mm][Gg][^>]*?[Ss][Rr][Cc]\s*=\s*["']([^"']+?)["'][^>]*?>''',
  // ["\']([^"\']+)["\']
  static final RegExp _imgPattern = RegExp(
      //r'''.*?<[Ii][Mm][Gg]\s+[^>]*[Ss][Rr][Cc]\s*=\s*["']([^"']+)["'][^>]*?>.*?''',
      r'''<[Ii][Mm][Gg]\s+[^>]*[Ss][Rr][Cc]\s*=\s*["\']([^"\']+)["\'][^>]*?>''',
      // r'''<img\s+[^>]*?src\s*=\s*["\']([^"\']+)["\'][^>]*?>'''
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
      unicode: false);

  static List<ContentPart> parseContent(String content) {
    List<ContentPart> parts = [];
    int lastIndex = 0;

    content = content.replaceAll('“', '"').replaceAll('”', '"');

    // 모든 매치(YouTube URL과 이미지 태그)를 찾아서 위치 순서대로 정렬
    List<Match> allMatches = [
      ..._youtubeUrlPattern.allMatches(content),
      ..._imgPattern.allMatches(content),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (Match match in allMatches) {
      if (match.start > lastIndex) {
        String beforeText = content.substring(lastIndex, match.start).trim();
        if (beforeText.isNotEmpty) {
          parts.add(TextPart(beforeText));
        }
      }

      // YouTube URL 매치인지 이미지 태그 매치인지 확인
      if (_youtubeUrlPattern.hasMatch(match.group(0)!)) {
        String? videoId = match.group(1);
        if (videoId != null) {
          parts.add(YoutubePart(
            videoId: videoId,
            originalUrl: match.group(0) ?? '',
          ));
        }
        // } else if (_imgPattern.hasMatch(match.group(0)!)) {
        //   String? imageUrl = match.group(1);
        //   if (imageUrl != null) {
        //     parts.add(ImagePart(
        //       imageUrl: imageUrl,
        //       originalTag: match.group(0) ?? '',
        //     ));
        //   }
        // }
      } else if (match.group(1) != null) {
        // 이미지 URL 매치
        lo.g("match.group(1).toString() : ${match.group(1).toString()}");

        String imageUrl = match.group(1)!;
        parts.add(ImagePart(
          imageUrl: imageUrl,
          originalTag: match.group(0) ?? '',
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      String remainingText = content.substring(lastIndex).trim();
      if (remainingText.isNotEmpty) {
        parts.add(TextPart(remainingText));
      }
    }

    return parts;
  }
}

abstract class ContentPart {}

class TextPart extends ContentPart {
  final String text;
  TextPart(this.text);
}

class YoutubePart extends ContentPart {
  final String videoId;
  final String originalUrl;
  YoutubePart({required this.videoId, required this.originalUrl});
}

// ContentPart에 ImagePart 추가
class ImagePart extends ContentPart {
  final String imageUrl;
  final String originalTag;
  ImagePart({required this.imageUrl, required this.originalTag});
}
