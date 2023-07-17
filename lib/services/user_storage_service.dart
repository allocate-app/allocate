import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'isar_service.dart';
import 'supabase_service.dart';

class UserStorageService {
  final SupabaseClient _supabaseClient = SupabaseService.supabaseClient;
  final Isar _isarClient = IsarService.isarClient;
}
