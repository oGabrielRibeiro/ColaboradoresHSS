import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/empresas_screen.dart';

void main() {
  testWidgets('Criar empresa - fluxo completo', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const MaterialApp(home: EmpresasScreen()));

    // Verifica FAB existe
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap FAB
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verifica modal apareceu
    expect(find.text('Nova Empresa'), findsOneWidget);

    // Digitar nome
    await tester.enterText(find.byType(TextField), 'Empresa Teste');

    // Tap Criar
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    // Verifica se empresas apareceu na lista
    expect(find.text('Empresa Teste'), findsOneWidget);
  });
}
