// lib/utils/validators.dart
// Hàm validate dùng chung cho form

class AppValidators {
  /// Kiểm tra định dạng email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  /// Kiểm tra số điện thoại Việt Nam (10 số, bắt đầu bằng 0)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    final regex = RegExp(r'^0\d{9}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Số điện thoại phải có 10 chữ số, bắt đầu bằng 0';
    }
    return null;
  }

  /// Họ tên bắt buộc
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    if (value.trim().length < 2) {
      return 'Họ tên quá ngắn';
    }
    return null;
  }

  /// Địa chỉ bắt buộc
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ';
    }
    return null;
  }
}
