@echo off
echo 设置Flutter中国镜像源...
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo 清理项目...
flutter clean

echo 获取依赖...
flutter pub get

echo 开始构建APK...
flutter build apk --release

echo 构建完成！
pause