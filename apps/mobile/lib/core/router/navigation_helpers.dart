import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigateBackOrHome(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  context.go('/');
}
