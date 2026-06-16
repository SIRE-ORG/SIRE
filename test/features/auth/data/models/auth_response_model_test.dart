import 'package:flutter_test/flutter_test.dart';
import 'package:sire/features/auth/data/models/auth_response_model.dart';
import 'package:sire/features/auth/domain/entities/auth_result.dart';
import 'package:sire/features/auth/domain/entities/user_profile.dart';

void main() {
  group('AuthResponseModel', () {
    final activeJson = {
      'userId': 'user-001',
      'accountStatus': 'active',
      'userCreated': false,
      'token': 'jwt-token-abc',
    };

    final guestJson = {
      'userId': 'user-002',
      'accountStatus': 'guest',
      'userCreated': true,
      'token': null,
    };

    group('fromJson', () {
      test('parsea userId correctamente', () {
        final model = AuthResponseModel.fromJson(activeJson);
        expect(model.userId, 'user-001');
      });

      test('parsea accountStatus active', () {
        final model = AuthResponseModel.fromJson(activeJson);
        expect(model.accountStatus, 'active');
      });

      test('parsea userCreated false', () {
        final model = AuthResponseModel.fromJson(activeJson);
        expect(model.userCreated, false);
      });

      test('parsea token correctamente', () {
        final model = AuthResponseModel.fromJson(activeJson);
        expect(model.token, 'jwt-token-abc');
      });

      test('parsea token nulo', () {
        final model = AuthResponseModel.fromJson(guestJson);
        expect(model.token, isNull);
      });

      test('parsea accountStatus guest', () {
        final model = AuthResponseModel.fromJson(guestJson);
        expect(model.accountStatus, 'guest');
      });

      test('parsea userCreated true', () {
        final model = AuthResponseModel.fromJson(guestJson);
        expect(model.userCreated, true);
      });
    });

    group('toEntity', () {
      test('accountStatus active se convierte a AccountStatus.active', () {
        final model = AuthResponseModel.fromJson(activeJson);
        final entity = model.toEntity();
        expect(entity.accountStatus, AccountStatus.active);
      });

      test('accountStatus guest se convierte a AccountStatus.guest', () {
        final model = AuthResponseModel.fromJson(guestJson);
        final entity = model.toEntity();
        expect(entity.accountStatus, AccountStatus.guest);
      });

      test('userId se preserva en la entidad', () {
        final model = AuthResponseModel.fromJson(activeJson);
        final entity = model.toEntity();
        expect(entity.userId, 'user-001');
      });

      test('userCreated se preserva en la entidad', () {
        final model = AuthResponseModel.fromJson(guestJson);
        final entity = model.toEntity();
        expect(entity.userCreated, true);
      });

      test('retorna una instancia de AuthResult', () {
        final model = AuthResponseModel.fromJson(activeJson);
        expect(model.toEntity(), isA<AuthResult>());
      });

      test('accountStatus no reconocido resulta en guest', () {
        final json = {
          'userId': 'user-003',
          'accountStatus': 'unknown',
          'userCreated': false,
          'token': null,
        };
        final model = AuthResponseModel.fromJson(json);
        final entity = model.toEntity();
        expect(entity.accountStatus, AccountStatus.guest);
      });
    });

    group('constructor directo', () {
      test('constructor asigna todos los campos', () {
        const model = AuthResponseModel(
          userId: 'u-test',
          accountStatus: 'active',
          userCreated: false,
          token: 'token-xyz',
        );
        expect(model.userId, 'u-test');
        expect(model.accountStatus, 'active');
        expect(model.userCreated, false);
        expect(model.token, 'token-xyz');
      });

      test('constructor con token nulo', () {
        const model = AuthResponseModel(
          userId: 'u-test',
          accountStatus: 'guest',
          userCreated: true,
        );
        expect(model.token, isNull);
      });
    });
  });
}
