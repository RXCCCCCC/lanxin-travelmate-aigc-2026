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

  Future<SelectedPhoto?> pickFromGallery() => _pick('pickFromGallery');

  Future<SelectedPhoto?> takePhoto() => _pick('takePhoto');

  Future<SelectedPhoto?> _pick(String method) async {
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>(method);
      if (result == null) return null;
      return SelectedPhoto.fromMap(result);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
