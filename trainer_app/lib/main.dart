import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WtfApp(role: AppRole.trainer));
}
