import 'package:food_app/models/account.dart';

// Danh sách tài khoản (mock data, lưu trong bộ nhớ runtime)
List<UserModel> mockUsers = [
  UserModel(
    username: 'admin',
    password: '123456',
    role: 'admin',
  ),
  UserModel(
    username: 'user',
    password: '123456',
    role: 'user',
  ),
];

/// Thêm tài khoản mới vào danh sách (role mặc định là 'user')
bool registerUser({
  required String username,
  required String password,
}) {
  // Kiểm tra username đã tồn tại chưa
  final exists = mockUsers.any((u) => u.username == username);
  if (exists) return false;

  mockUsers.add(UserModel(
    username: username,
    password: password,
    role: 'user',
  ));
  return true;
}