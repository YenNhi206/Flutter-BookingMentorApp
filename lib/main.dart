import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'viewmodels/auth_vm.dart';
import 'viewmodels/cart_vm.dart';
import 'viewmodels/chat_vm.dart';
import 'viewmodels/favourite_vm.dart';
import 'viewmodels/food_vm.dart';
import 'viewmodels/main_tab_vm.dart';
import 'viewmodels/notification_vm.dart';
import 'viewmodels/order_vm.dart';
import 'views/screens/splash_screen.dart';

/// Điểm khởi động app Scoops. Đăng ký toàn bộ ViewModel (MVVM) vào
/// [MultiProvider] ở gốc cây widget để mọi màn hình bên dưới đều truy cập
/// được qua `context.watch`/`context.read`.
void main() {
  runApp(const ScoopsApp());
}

class ScoopsApp extends StatelessWidget {
  const ScoopsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FoodViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => MainTabViewModel()),
        ChangeNotifierProvider(create: (_) => FavouriteViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: MaterialApp(
        title: 'Scoops',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
