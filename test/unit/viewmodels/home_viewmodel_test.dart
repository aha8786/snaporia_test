/*
import 'package:flutter_test/flutter_test.dart';
import 'package:snaporia/models/user_model.dart';
import 'package:snaporia/services/user_service.dart';
import 'package:snaporia/viewmodels/home_view_model.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<UserService>()])
import 'home_viewmodel_test.mocks.dart';

void main() {
  late HomeViewModel viewModel;
  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
    viewModel = HomeViewModel(userService: mockUserService);
  });

  group('HomeViewModel Tests', () {
    test('초기 상태 테스트', () {
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('사용자 로드 성공 테스트', () async {
      final testUser = UserModel(
        id: 1,
        name: '테스트 사용자',
        email: 'test@example.com',
      );

      when(mockUserService.getCurrentUser()).thenAnswer((_) async => testUser);

      await viewModel.loadCurrentUser();

      expect(viewModel.currentUser, equals(testUser));
      expect(viewModel.isLoading, isFalse);
    });

    test('사용자 로드 실패 테스트', () async {
      when(mockUserService.getCurrentUser()).thenThrow(Exception('로드 실패'));

      await viewModel.loadCurrentUser();

      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('사용자 업데이트 성공 테스트', () async {
      final testUser = UserModel(
        id: 1,
        name: '업데이트된 사용자',
        email: 'updated@example.com',
      );

      when(mockUserService.saveUser(testUser)).thenAnswer((_) async => true);

      final result = await viewModel.updateUser(testUser);

      expect(result, isTrue);
      expect(viewModel.currentUser, equals(testUser));
      expect(viewModel.isLoading, isFalse);
    });
  });
}
*/
