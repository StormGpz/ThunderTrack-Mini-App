import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// 个人页面，显示用户信息、头像设置和日记管理
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 手动获取Provider实例进行测试
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('🔍 手动获取Provider: ${userProvider.hashCode}');
    print('🔍 手动获取用户: ${userProvider.currentUser?.username ?? "null"}');
    print('🔍 手动获取认证状态: ${userProvider.isAuthenticated}');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final provider = Provider.of<UserProvider>(context, listen: false);
              await provider.logout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              '退出登录',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      // 强制显示内容，不依赖Consumer
      body: Column(
        children: [
          // 始终显示的测试区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red,
            child: Column(
              children: [
                const Text(
                  '🔍 测试区域 - 基本渲染正常',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '手动获取认证状态: ${userProvider.isAuthenticated}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '手动获取用户: ${userProvider.currentUser?.username ?? "null"}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          // Consumer内容区域
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, consumerProvider, child) {
                try {
                  final user = consumerProvider.currentUser;
                  
                  print('🔍 === Consumer调试 ===');
                  print('   Consumer Provider哈希: ${consumerProvider.hashCode}');
                  print('   手动Provider哈希: ${userProvider.hashCode}');
                  print('   是否同一个实例: ${identical(consumerProvider, userProvider)}');
                  print('   Consumer认证状态: ${consumerProvider.isAuthenticated}');
                  print('   Consumer用户: ${user?.username ?? "null"}');
                  print('🔍 ===================');
                  
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.blue,
                        child: Column(
                          children: [
                            const Text(
                              '🔍 Consumer调试信息',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Consumer已认证: ${consumerProvider.isAuthenticated}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              'Consumer用户: ${user?.username ?? "null"}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              'Provider相同: ${identical(consumerProvider, userProvider)}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildUserContent(consumerProvider, user),
                      ),
                    ],
                  );
                } catch (e, stackTrace) {
                  print('❌ Consumer builder异常: $e');
                  print('❌ 堆栈跟踪: $stackTrace');
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.orange,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          '🚨 Consumer渲染异常',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '错误: $e',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserContent(UserProvider userProvider, dynamic user) {
    try {
      if (!userProvider.isAuthenticated) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('用户未登录'),
              SizedBox(height: 8),
              Text('请返回主页进行登录', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
      
      if (user == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('用户信息加载中...'),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // 用户头像
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo.withValues(alpha: 0.2),
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 头像加载失败时显示默认图标
                          return user.isVerified
                              ? const Icon(
                                  Icons.verified_user,
                                  color: Colors.indigo,
                                  size: 50,
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.indigo,
                                  size: 50,
                                );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator(
                            color: Colors.indigo,
                            strokeWidth: 2,
                          );
                        },
                      ),
                    )
                  : (user.isVerified
                      ? const Icon(
                          Icons.verified_user,
                          color: Colors.indigo,
                          size: 50,
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.indigo,
                          size: 50,
                        )),
            ),
            const SizedBox(height: 16),

            // 用户名和显示名
            Text(
              user.displayName ?? '未知用户',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username ?? "unknown"}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            // 验证徽章
            if (user.isVerified == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.indigo),
                    SizedBox(width: 4),
                    Text(
                      '已验证用户',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 用户简介
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                user.bio ?? '这位用户还没有添加个人简介',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 统计信息 - 添加空值检查
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('关注', (user.following?.length ?? 0).toString()),
                _buildStatItem('粉丝', (user.followers?.length ?? 0).toString()),
                _buildStatItem('FID', user.fid?.substring(0, user.fid!.length > 8 ? 8 : user.fid!.length) ?? 'N/A'),
              ],
            ),

            const SizedBox(height: 20),

            // 钱包地址
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '钱包地址',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.walletAddress ?? '未连接钱包',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 底部说明
            Text(
              '注意：这是本地测试账号，所有数据仅用于演示',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('❌ _buildUserContent异常: $e');
      print('❌ 堆栈跟踪: $stackTrace');
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: Colors.purple,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              '🐛 用户内容渲染异常',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '错误: $e',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}