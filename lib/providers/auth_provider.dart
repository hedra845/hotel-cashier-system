import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<AppUser> _allUsers = [];

  AppUser? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  List<AppUser> get allUsers => _allUsers;

  AuthProvider() {
    _loadUser();
    _loadAllUsers();
  }

  Future<void> _loadUser() async {
    try {
      _currentUser = await _dbHelper.getUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      _allUsers = await _dbHelper.getAllUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all users: $e');
    }
  }

  Future<void> login(String name, String password, UserRole role) async {
    try {
      // التحقق من وجود المستخدم في قاعدة البيانات أولاً
      final users = await _dbHelper.getAllUsers();
      final existingUser = users.where((u) => u.name == name).firstOrNull;

      if (existingUser != null) {
        if (existingUser.password != password) {
          throw Exception('كلمة المرور غير صحيحة');
        }
        _currentUser = existingUser;
      } else {
        // إذا كان أول دخول، نعتبره مديراً افتراضياً (للتجربة) أو ننشئ حساب جديد
        if (password != '123456') {
          throw Exception('كلمة المرور غير صحيحة');
        }
        _currentUser = AppUser(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          email: '$name@hotel.com',
          password: password,
          role: role,
        );
        await _dbHelper.insertUser(_currentUser!);
      }

      await _loadAllUsers();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addNewUser(String name, String password, UserRole role) async {
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: '$name@hotel.com',
      password: password,
      role: role,
    );
    await _dbHelper.insertUser(newUser);
    await _loadAllUsers();
  }

  Future<void> updateUserDetails(
    String userId, {
    String? name,
    String? password,
    UserRole? role,
  }) async {
    final user = _allUsers.firstWhere((u) => u.id == userId);
    final updatedUser = user.copyWith(
      name: name ?? user.name,
      password: password ?? user.password,
      role: role ?? user.role,
      email: name != null ? '$name@hotel.com' : user.email,
    );
    await _dbHelper.insertUser(updatedUser);

    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
    }

    await _loadAllUsers();
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await updateUserDetails(userId, role: newRole);
  }

  Future<void> deleteUser(String userId) async {
    if (_currentUser?.id == userId) {
      throw Exception('لا يمكنك حذف حسابك الحالي');
    }
    await _dbHelper.deleteUser(userId);
    await _loadAllUsers();
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null && _currentUser != null) {
      _currentUser = _currentUser!.copyWith(imagePath: image.path);
      await _dbHelper.insertUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _dbHelper.clearUsers();
    _currentUser = null;
    notifyListeners();
  }
}
