// 데이터 클래스
import 'package:image_picker/image_picker.dart';

class ImageData {
  XFile? file; // 로컬 파일 참조 (업로드 전)
  String imageKey;
  final String fileName;
  String imageUrl;
  bool isDeleting = false;

  ImageData({
    this.file,
    required this.imageKey,
    required this.fileName,
    required this.imageUrl,
    this.isDeleting = false,
  });

  // 이미지가 업로드되었는지 확인하는 getter
  bool get isUploaded => imageKey.isNotEmpty;

  // equals 메소드 추가
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageData && runtimeType == other.runtimeType && fileName == other.fileName && imageKey == other.imageKey;

  // hashCode 메소드 추가
  @override
  int get hashCode => fileName.hashCode ^ imageKey.hashCode;
}
