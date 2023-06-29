import "package:supabase_flutter/supabase_flutter.dart";
import "../model/task/routine.dart";

class SupabaseService{

  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  static late final SupabaseClient _supabaseClient;
  
  static SupabaseClient get supabaseClient => _supabaseClient;

  init() async {
    await Supabase.initialize(
    url: "fakeurl",
    anonKey: "public-anonkey",
  );
  _supabaseClient = Supabase.instance.client;
  }

  SupabaseService._internal();
}