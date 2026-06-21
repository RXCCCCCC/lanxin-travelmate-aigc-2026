import 'package:flutter/services.dart';

class SelectedPhoto {
  const SelectedPhoto({
    required this.localUri,
    required this.filename,
    required this.mimeType,
    required this.source,
  });

  final String localUri;
  final String filename;
  final String mimeType;
  final String source;

  factory SelectedPhoto.fromMap(Map<dynamic, dynamic> map) {
    return SelectedPhoto(
      localUri: map['localUri']?.toString() ?? '',
      filename: map['filename']?.toString() ?? 'selected-photo.jpg',
      mimeType: map['mimeType']?.toString() ?? 'image/jpeg',
      source: map['source']?.toString() ?? 'gallery',
    );
  }
}

class PhotoSelectionService {
  PhotoSelectionService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('lanxin_travelmate/photo_picker');

  final MethodChannel _channel;
  String? lastFailureMessage;

  Future<SelectedPhoto?> pickFromGallery() => _pick('pickFromGallery');

  Future<SelectedPhoto?> takePhoto() => _pick('takePhoto');

  Future<SelectedPhoto?> _pick(String method) async {
    lastFailureMessage = null;
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(method);
      if (result == null) return null;
      return SelectedPhoto.fromMap(result);
    } on MissingPluginException {
      lastFailureMessage = '当前 Android 设备未接入系统相册/相机通道';
      return null;
    } on PlatformException catch (error) {
      lastFailureMessage = _messageForPlatformError(error);
      return null;
    }
  }

  String _messageForPlatformError(PlatformException error) {
    return switch (error.code) {
      'gallery_unavailable' => '未找到可用的系统相册应用，请检查相册应用或改用相机拍摄',
      'camera_output_unavailable' => '无法创建相机照片文件，请检查存储空间后重试',
      'camera_unavailable' => '未找到可用的系统相机应用，请检查相机应用',
      'picker_busy' => '正在处理上一张照片，请稍后再试',
      _ => error.message ?? '系统相册/相机暂不可用，请稍后重试',
    };
  }
}
