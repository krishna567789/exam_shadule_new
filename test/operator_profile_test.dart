import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_shadule_new/models/operator_profile_model.dart';

void main() {
  test('OperatorProfileResponse parses JSON correctly', () {
    const rawJson = '''
    {
      "status": true,
      "profileCompleted": true,
      "data": {
        "profile": {
          "id": "6a89771fcd814b81d8401b1b",
          "registrarId": "6a894932cd814b81d83ff333",
          "operatorId": "100001",
          "name": "test user",
          "fatherName": "test father",
          "mobileNumber": "3255094558",
          "email": "sainicoders20@gmail.com",
          "address": "gomti nagar",
          "role": "operator",
          "state": "up",
          "city": "lucknow",
          "aadharFront": "https://ubro-space.blr1.cdn.digitaloceanspaces.com/biomatric_august/operators/aadhar-front/1787393823584_b24f7a57-03e1-4dfd-849b-072e7c898f22.jpeg",
          "aadharBack": "https://ubro-space.blr1.cdn.digitaloceanspaces.com/biomatric_august/operators/aadhar-back/1787393823613_edc76423-f642-4d8b-a8d8-81deb60d6b9a.jpeg",
          "photo": "https://ubro-space.blr1.cdn.digitaloceanspaces.com/biomatric_august/operators/profile/1787393823522_1f14b73d-ae09-4229-9c8c-a0715b319e0f.jpeg",
          "createdAt": "2026-08-22T10:17:03.642Z",
          "updatedAt": "2026-08-22T10:17:03.642Z"
        }
      }
    }
    ''';

    final decoded = json.decode(rawJson);
    final response = OperatorProfileResponse.fromJson(decoded);

    expect(response.status, true);
    expect(response.profileCompleted, true);
    expect(response.data, isNotNull);

    final profile = response.data!.profile!;
    expect(profile.id, '6a89771fcd814b81d8401b1b');
    expect(profile.registrarId, '6a894932cd814b81d83ff333');
    expect(profile.operatorId, '100001');
    expect(profile.name, 'test user');
    expect(profile.fatherName, 'test father');
    expect(profile.mobileNumber, '3255094558');
    expect(profile.email, 'sainicoders20@gmail.com');
    expect(profile.address, 'gomti nagar');
    expect(profile.role, 'operator');
    expect(profile.state, 'up');
    expect(profile.city, 'lucknow');
    expect(profile.aadharFront, contains('aadhar-front'));
    expect(profile.aadharBack, contains('aadhar-back'));
    expect(profile.photo, contains('profile'));
  });
}
