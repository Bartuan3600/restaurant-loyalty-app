import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/notify.dart';
import 'src/repository.dart';
import 'src/tenant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tenant = await Tenant.load();
  await tenant.loadFonts();
  // Swap for a SupabaseLoyaltyRepository later – the UI only knows the interface.
  final LoyaltyRepository repo = LocalLoyaltyRepository(tenant);
  await repo.init();
  await Notify.init();
  runApp(LoyaltyApp(tenant: tenant, repo: repo));
}
