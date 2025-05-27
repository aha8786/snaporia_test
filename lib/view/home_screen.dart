import 'package:flutter/material.dart';
import '../viewmodel/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel viewModel = HomeViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.initialize();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snaporia'),
        actions: [
          // 라벨링 검색 중일 때 로딩 스피너 표시
          if (viewModel.isLabelingSearch)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // ... existing code ...
        ],
      ),
      // ... existing code ...
    );
  }

  /// 키워드 검색 다이얼로그 표시
  void _showKeywordSearchDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('키워드 검색'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('검색할 키워드를 입력해주세요.'),
            const SizedBox(height: 8),
            const Text('• 한글로 입력하면 자동으로 영어로 변환됩니다.'),
            const Text('• 영어로 입력하실 경우 소문자로만 입력해주세요 (예: Dog → dog)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '예: 사람, dog, cat',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  viewModel.setSearchKeyword(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text;
              if (text.isNotEmpty) {
                viewModel.setSearchKeyword(text);
              }
              Navigator.pop(context);
            },
            child: const Text('검색'),
          ),
        ],
      ),
    );
  }
}
