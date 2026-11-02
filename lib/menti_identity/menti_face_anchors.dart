// Measured from existing source pixels by tool/index_menti_face_anchors.py.
import 'dart:ui';

class MentiFaceAnchors {
  static const values = <String, Map<String, Rect>>{
    'boy-young': {
      'leftEye': Rect.fromLTWH(330, 176, 78, 67),
      'rightEye': Rect.fromLTWH(438, 201, 62, 64),
      'mouth': Rect.fromLTWH(347, 246, 106, 67),
      'skull': Rect.fromLTWH(268, 139, 253, 190),
    },
    'boy-young-clean': {
      'leftEye': Rect.fromLTWH(330, 174, 79, 68),
      'rightEye': Rect.fromLTWH(438, 199, 63, 65),
      'mouth': Rect.fromLTWH(350, 246, 102, 65),
      'skull': Rect.fromLTWH(255, 73, 273, 254),
    },
    'boy-adult': {
      'leftEye': Rect.fromLTWH(898, 128, 78, 68),
      'rightEye': Rect.fromLTWH(1006, 147, 61, 64),
      'mouth': Rect.fromLTWH(916, 200, 107, 64),
      'skull': Rect.fromLTWH(837, 86, 247, 194),
    },
    'boy-adult-clean': {
      'leftEye': Rect.fromLTWH(900, 126, 79, 69),
      'rightEye': Rect.fromLTWH(1009, 144, 61, 66),
      'mouth': Rect.fromLTWH(919, 200, 105, 62),
      'skull': Rect.fromLTWH(827, 35, 267, 243),
    },
    'boy-veteran': {
      'leftEye': Rect.fromLTWH(1496, 138, 76, 65),
      'rightEye': Rect.fromLTWH(1603, 161, 60, 60),
      'mouth': Rect.fromLTWH(1516, 212, 102, 64),
      'skull': Rect.fromLTWH(1433, 75, 251, 217),
    },
    'boy-veteran-clean': {
      'leftEye': Rect.fromLTWH(1500, 136, 76, 66),
      'rightEye': Rect.fromLTWH(1606, 160, 61, 60),
      'mouth': Rect.fromLTWH(1515, 211, 107, 66),
      'skull': Rect.fromLTWH(1425, 44, 264, 249),
    },
    'girl-young': {
      'leftEye': Rect.fromLTWH(426, 168, 64, 55),
      'rightEye': Rect.fromLTWH(521, 191, 43, 52),
      'mouth': Rect.fromLTWH(441, 227, 77, 52),
      'skull': Rect.fromLTWH(322, 86, 256, 209),
    },
    'girl-young-clean': {
      'leftEye': Rect.fromLTWH(402, 138, 72, 60),
      'rightEye': Rect.fromLTWH(513, 162, 50, 57),
      'mouth': Rect.fromLTWH(428, 212, 78, 48),
      'skull': Rect.fromLTWH(333, 53, 247, 237),
    },
    'girl-adult': {
      'leftEye': Rect.fromLTWH(916, 146, 66, 55),
      'rightEye': Rect.fromLTWH(1024, 160, 41, 52),
      'mouth': Rect.fromLTWH(942, 211, 78, 46),
      'skull': Rect.fromLTWH(893, 88, 186, 185),
    },
    'girl-adult-clean': {
      'leftEye': Rect.fromLTWH(913, 119, 72, 60),
      'rightEye': Rect.fromLTWH(1030, 135, 47, 57),
      'mouth': Rect.fromLTWH(943, 194, 76, 45),
      'skull': Rect.fromLTWH(851, 22, 246, 234),
    },
    'girl-veteran': {
      'leftEye': Rect.fromLTWH(1470, 153, 65, 53),
      'rightEye': Rect.fromLTWH(1578, 166, 43, 52),
      'mouth': Rect.fromLTWH(1499, 224, 71, 42),
      'skull': Rect.fromLTWH(1435, 85, 208, 199),
    },
    'girl-veteran-clean': {
      'leftEye': Rect.fromLTWH(1474, 131, 71, 56),
      'rightEye': Rect.fromLTWH(1591, 145, 49, 54),
      'mouth': Rect.fromLTWH(1506, 207, 75, 44),
      'skull': Rect.fromLTWH(1407, 24, 262, 249),
    },
    'neutral-young': {
      'leftEye': Rect.fromLTWH(349, 158, 40, 49),
      'rightEye': Rect.fromLTWH(463, 176, 37, 49),
      'mouth': Rect.fromLTWH(392, 225, 46, 31),
      'skull': Rect.fromLTWH(292, 112, 223, 160),
    },
    'neutral-young-clean': {
      'leftEye': Rect.fromLTWH(343, 150, 40, 50),
      'rightEye': Rect.fromLTWH(461, 165, 39, 52),
      'mouth': Rect.fromLTWH(388, 219, 47, 32),
      'skull': Rect.fromLTWH(285, 46, 233, 223),
    },
    'neutral-adult': {
      'leftEye': Rect.fromLTWH(900, 130, 36, 46),
      'rightEye': Rect.fromLTWH(1007, 145, 33, 47),
      'mouth': Rect.fromLTWH(940, 197, 47, 31),
      'skull': Rect.fromLTWH(829, 3, 224, 245),
    },
    'neutral-adult-clean': {
      'leftEye': Rect.fromLTWH(901, 122, 41, 49),
      'rightEye': Rect.fromLTWH(1016, 137, 37, 49),
      'mouth': Rect.fromLTWH(946, 193, 47, 31),
      'skull': Rect.fromLTWH(842, 16, 227, 229),
    },
    'neutral-veteran': {
      'leftEye': Rect.fromLTWH(1450, 135, 37, 43),
      'rightEye': Rect.fromLTWH(1558, 146, 31, 47),
      'mouth': Rect.fromLTWH(1496, 207, 41, 28),
      'skull': Rect.fromLTWH(1385, 71, 217, 197),
    },
    'neutral-veteran-clean': {
      'leftEye': Rect.fromLTWH(1451, 129, 42, 46),
      'rightEye': Rect.fromLTWH(1566, 141, 33, 48),
      'mouth': Rect.fromLTWH(1495, 204, 49, 29),
      'skull': Rect.fromLTWH(1388, 29, 228, 239),
    },
  };
}
