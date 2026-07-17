/// Chuỗi text và hằng số dùng chung toàn app - gom vào đây để không hardcode
/// trực tiếp trong widget, dễ sửa/đa ngôn ngữ hoá sau này.
class AppConstants {
  AppConstants._();

  static const String appName = 'Scoops';
  static const String appTagline = 'Order & Eat';

  // Onboarding
  static const String onboardingHeadline = 'A Sweet Escape in\nEvery Single Scoop';
  static const String onboardingSubtitle =
      'Handcrafted ice cream, cakes and drinks — freshly churned and delivered right to your door.';
  static const String joinMember = 'Join Member';
  static const String continueAsGuest = 'Continue as Guest';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String createAccount = 'Create account';
  static const String logIn = 'Log In';
  static const String signUp = 'Sign Up';
  static const String forgotPassword = 'Forgot password?';
  static const String emailHint = 'you@example.com';
  static const String passwordHint = 'At least 6 characters';

  // Home
  static const String discoverFood = 'Discover food';
  static const String searchHint = 'Search for sweets...';
  static const String weRecommend = 'We Recommend';
  static const String filterAll = 'All';

  // Cart / Checkout
  static const String yourCartIsEmpty = 'Your cart is empty';
  static const String browseSweets = 'Browse sweets';
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String orderPlaced = 'Order placed!';

  // Payment methods
  static const String paymentCod = 'Cash on Delivery';
  static const String paymentBankTransfer = 'Bank Transfer';
  static const String paymentMomo = 'MoMo';

  // Business rules
  static const double deliveryFee = 1.50;
  static const int lowStockThreshold = 5;

  /// Người dùng demo được seed sẵn để chấm bài không cần đăng ký lại.
  static const String demoEmail = 'demo@scoops.com';
  static const String demoPassword = '123456';

  /// Chủ quán demo (role owner, gắn sẵn store_1) để test màn Quản lý quán.
  static const String demoOwnerEmail = 'owner@scoops.com';
  static const String demoOwnerPassword = '123456';
}
