import "package:supabase_flutter/supabase_flutter.dart";
import "../model/task/routine.dart";

class SupabaseService{

  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;

  late SupabaseClient supabaseInstance;


  init() async {
    await Supabase.initialize(
    url: "fakeurl",
    anonKey: "public-anonkey",
  );
  supabaseInstance = Supabase.instance.client;
  }

  // refactor this to use supabase.
  Future<int?> insertOneRoutine(Map<String, dynamic> routineEntity) async{
    final List<Map<String, dynamic>> response = await supabaseInstance
        .from("routines")
        .insert(routineEntity)
        .select("id");
    Map<String, dynamic> latestUpdated = response.last;
    return latestUpdated["id"];
  }

  List<Routine> getRoutines()
  {
    // TODO: implement using db query.
    List<Routine> routines = List.empty(growable: true);
    return routines;
  }

  SupabaseService._internal();
}