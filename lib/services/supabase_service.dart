import "package:supabase_flutter/supabase_flutter.dart";

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  static late final SupabaseClient _supabaseClient;

  static SupabaseClient get supabaseClient => _supabaseClient;

  init({required String supabaseUrl, required String anonKey}) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
    );
    _supabaseClient = Supabase.instance.client;
  }

  SupabaseService._internal();
}
