import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/user_profile_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<AuthResponseModel> registerGuest({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await dio.post(
      ApiConstants.authRegisterGuest,
      data: {'name': name, 'email': email, 'phone': phone},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateAccountStatus() async {
    await dio.patch(ApiConstants.authAccountStatus);
  }

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await dio.get(ApiConstants.usersMe);
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final body = UpdateProfileRequestModel(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
    ).toJson();
    final response = await dio.put(ApiConstants.usersMe, data: body);
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
