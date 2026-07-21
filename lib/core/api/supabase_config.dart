import 'supabase_client.dart';

class SupabaseConfig {
  // Table names
  static const String tableChemicalUsage = 'chemical_usage';
  static const String tableChemicals = 'chemicals';
  static const String tableLabAssets = 'lab_assets';
  static const String tableReservationItems = 'reservation_items';
  static const String tableReservations = 'reservations';
  static const String tableRooms = 'rooms';
  static const String tableUserInfo = 'user_info';
  static const String tableStockHistory = 'stock_history';

  // Storage buckets
  static const String bucketAvatars = 'avatars';
  static const String bucketDocuments = 'documents';

  // Initialize Supabase
  static Future<void> initialize() async {
    await SupabaseService.initialize();
  }
}
