import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// 1. TẦNG MODEL (Dữ liệu & Factory phân tích JSON)
// ============================================================================
class Post {
  final int id;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.title,
    required this.body,
  });

  // Factory Constructor: Ánh xạ từ Map/JSON sang Object
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

// ============================================================================
// 2. TẦNG NETWORK SERVICE (Đóng gói gọi REST API độc lập)
// ============================================================================
class ApiService {
  /// Giả lập gọi API lấy dữ liệu tiếng Việt thực tế
  Future<List<Post>> fetchPosts() async {
    // Giả lập độ trễ mạng 1.2 giây để nhìn rõ trạng thái xoay vòng Loading
    await Future.delayed(const Duration(milliseconds: 1200));

    // Dữ liệu mẫu tiếng Việt dạng List<Map> chuẩn như server trả về
    final List<Map<String, dynamic>> mockDataFromApi = [
      {
        'id': 1,
        'title': 'Học lập trình Flutter cơ bản đến nâng cao',
        'body':
            'Tìm hiểu về Widget, State và cách xây dựng giao diện đa nền tảng mượt mà.'
      },
      {
        'id': 2,
        'title': 'Kiến trúc MVVM trong ứng dụng di động',
        'body':
            'Tách biệt rõ ràng giữa Model, View và ViewModel giúp mã nguồn dễ bảo trì và mở rộng.'
      },
      {
        'id': 3,
        'title': 'Quản lý trạng thái với ChangeNotifier',
        'body':
            'Cơ chế thông báo cập nhật giao diện tự động bằng mô hình Observer có sẵn trong Flutter.'
      },
      {
        'id': 4,
        'title': 'Xử lý lỗi mạng và hiển thị trạng thái Retry',
        'body':
            'Đảm bảo trải nghiệm người dùng luôn mượt mà khi gặp sự cố mất kết nối hoặc timeout.'
      },
      {
        'id': 5,
        'title': 'Kế hoạch học tập và đồ án qua môn',
        'body':
            'Hoàn thành bài tập lớn xuất sắc để đạt điểm tuyệt đối từ thầy giáo hướng dẫn!'
      },
    ];

    // Ánh xạ sang danh sách Post thông qua Factory Constructor
    return mockDataFromApi.map((item) => Post.fromJson(item)).toList();
  }
}

// ============================================================================
// 3. TẦNG VIEWMODEL (Logic nghiệp vụ & Quản lý trạng thái)
// ============================================================================
enum ViewState { loading, success, error }

class PostViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ViewState _state = ViewState.loading;
  ViewState get state => _state;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  /// Tải dữ liệu và phát tín hiệu cho View thông qua notifyListeners()
  Future<void> loadPosts() async {
    // 1. Chuyển trạng thái sang Loading
    _state = ViewState.loading;
    notifyListeners();

    try {
      // 2. Gọi tầng Service lấy dữ liệu
      _posts = await _apiService.fetchPosts();
      _state = ViewState.success;
    } catch (e) {
      // 3. Bắt lỗi và lưu thông báo
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = ViewState.error;
    } finally {
      // 4. Phát tín hiệu cập nhật giao diện
      notifyListeners();
    }
  }
}

// ============================================================================
// 4. TẦNG VIEW (Giao diện người dùng thuần túy)
// ============================================================================
class PostView extends StatefulWidget {
  const PostView({super.key});

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  // View nắm giữ đối tượng ViewModel
  final PostViewModel _viewModel = PostViewModel();

  @override
  void initState() {
    super.initState();
    // Gọi tải dữ liệu khi mở màn hình
    _viewModel.loadPosts();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiến Trúc MVVM - Đọc API'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // ListenableBuilder lắng nghe notifyListeners() từ ViewModel để vẽ lại body
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          switch (_viewModel.state) {
            // Trạng thái 1: Đang tải (Loading)
            case ViewState.loading:
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải dữ liệu từ máy chủ...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              );

            // Trạng thái 2: Báo lỗi kèm nút Thử lại (Error & Retry)
            case ViewState.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 70, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _viewModel
                            .loadPosts(), // Luồng dữ liệu 1 chiều: View kích hoạt ViewModel
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );

            // Trạng thái 3: Thành công (Success)
            case ViewState.success:
              return RefreshIndicator(
                onRefresh: () => _viewModel.loadPosts(), // Kéo xuống để reload
                child: ListView.separated(
                  itemCount: _viewModel.posts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final post = _viewModel.posts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${post.id}'),
                      ),
                      title: Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

// ============================================================================
// 5. ENTRY POINT (Hàm khởi chạy ứng dụng)
// ============================================================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo MVVM Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PostView(),
    );
  }
}
