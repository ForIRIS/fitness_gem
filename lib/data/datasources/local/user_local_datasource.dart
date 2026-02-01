import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile_model.dart';

/// Local data source for user profile data
abstract class UserLocalDataSource {
  /// Get user profile from local storage
  Future<UserProfileModel?> getUserProfile();

  /// Save user profile to local storage
  Future<void> saveUserProfile(UserProfileModel profile);

  /// Delete user profile from local storage
  Future<void> deleteUserProfile();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String _profileKey = 'user_profile';

  UserLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<UserProfileModel?> getUserProfile() async {
    final jsonString = sharedPreferences.getString(_profileKey);
    if (jsonString != null) {
      return UserProfileModel.fromJson(jsonString);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    await sharedPreferences.setString(_profileKey, profile.toJson());
  }

  @override
  Future<void> deleteUserProfile() async {
    await sharedPreferences.remove(_profileKey);
  }
}
