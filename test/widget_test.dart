import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mbongo/features/auth/domain/app_user.dart';
import 'package:mbongo/features/auth/presentation/auth_notifier.dart';
import 'package:mbongo/features/wallet/domain/wallet_state.dart';
import 'package:mbongo/features/wallet/presentation/wallet_notifier.dart';
import 'package:mbongo/screens/main_shell.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<AppUser?> build() async {
    return const AppUser(
      id: 'user-test',
      name: 'Client Test',
      phone: '0990000000',
      wallet: WalletInfo(id: 'wallet-test', balance: 20000, currency: 'CDF'),
    );
  }
}

class _TestWalletNotifier extends WalletNotifier {
  @override
  Future<WalletData?> build() async {
    return const WalletData(
      id: 'wallet-test',
      balance: 20000,
      currency: 'CDF',
      transactions: [],
    );
  }
}

void main() {
  testWidgets('MBONGO app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
          walletProvider.overrideWith(_TestWalletNotifier.new),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MBONGO'), findsWidgets);
    expect(find.text('Accueil'), findsWidgets);
  });
}
