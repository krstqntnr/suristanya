import 'package:image_picker/image_picker.dart';

enum BodyPart { tongue, palm, nail, eye }

extension BodyPartX on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.tongue:
        return 'Tongue';
      case BodyPart.palm:
        return 'Palm';
      case BodyPart.nail:
        return 'Nail';
      case BodyPart.eye:
        return 'Eye';
    }
  }

  String get subtitle {
    switch (this) {
      case BodyPart.tongue:
        return 'Stick out your tongue';
      case BodyPart.palm:
        return 'Show your open palm';
      case BodyPart.nail:
        return 'Fingernail, close up';
      case BodyPart.eye:
        return 'Lower eyelid';
    }
  }

  String get instruction {
    switch (this) {
      case BodyPart.tongue:
        return 'Stick out your tongue in natural daylight. Fill the frame with the tongue surface.';
      case BodyPart.palm:
        return 'Hold your palm open under bright, even light. Avoid shadows.';
      case BodyPart.nail:
        return 'Bring your fingernail close to the camera. Press lightly to see the color.';
      case BodyPart.eye:
        return 'Gently pull down your lower eyelid to expose the conjunctiva. Look up.';
    }
  }

  String get apiKey => name; // 'tongue', 'palm', 'nail', 'eye'
}

class BodyScan {
  final Map<BodyPart, XFile> images;
  const BodyScan({required this.images});

  bool get isComplete => images.length == BodyPart.values.length;
  bool hasImage(BodyPart part) => images.containsKey(part);
}
