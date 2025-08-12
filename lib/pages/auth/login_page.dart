import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

/// 登录页面，用于本地测试
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// 模拟登录功能
  Future<void> _simulateLogin() async {
    if (_usernameController.text.trim().isEmpty) {
      _showMessage('请输入用户名');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟网络延迟
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 调用模拟登录方法
      final success = await userProvider.simulateLogin(_usernameController.text.trim());
      
      if (success && mounted) {
        _showMessage('登录成功！');
        // 返回到主页面
        Navigator.of(context).pop();
      } else if (mounted) {
        _showMessage('登录失败，请重试');
      }
    } catch (e) {
      _showMessage('登录出错: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录 ThunderTrack'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo区域
            const Icon(
              Icons.flash_on,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            const Text(
              '⚡ ThunderTrack',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '去中心化交易日记应用',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // 用户名输入框
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: '输入任意用户名进行测试',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _simulateLogin(),
            ),
            const SizedBox(height: 24),

            // 登录按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _simulateLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '模拟登录',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),

            // 说明文字
            const Text(
              '注意：这是本地测试版本，输入任意用户名即可登录',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),

            // 快速登录按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      _usernameController.text = 'demo_user';
                      _simulateLogin();
                    },
                    child: const Text('快速登录 (demo_user)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      _usernameController.text = 'trader_001';
                      _simulateLogin();
                    },
                    child: const Text('快速登录 (trader_001)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}