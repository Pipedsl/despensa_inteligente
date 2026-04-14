import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:flutter_test/flutter_test.dart';

ItemDespensa _makeItem({DateTime? fechaVencimiento}) {
  final now = DateTime.now();
  return ItemDespensa(
    id: 'test-id',
    nombre: 'Leche',
    cantidad: 1.0,
    unidad: 'L',
    fechaVencimiento: fechaVencimiento,
    agregadoPor: 'user-1',
    estado: 'activo',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ItemDespensa.diasParaVencer', () {
    test('returns null when no fechaVencimiento', () {
      final item = _makeItem();
      expect(item.diasParaVencer, isNull);
    });

    test('returns 0 when vence hoy', () {
      final hoy = DateTime.now();
      final item = _makeItem(fechaVencimiento: DateTime(hoy.year, hoy.month, hoy.day));
      expect(item.diasParaVencer, 0);
    });

    test('returns negative when expired', () {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final item = _makeItem(fechaVencimiento: DateTime(ayer.year, ayer.month, ayer.day));
      expect(item.diasParaVencer, -1);
    });

    test('returns positive 10 for a future date 10 days away', () {
      final futuro = DateTime.now().add(const Duration(days: 10));
      final item = _makeItem(fechaVencimiento: DateTime(futuro.year, futuro.month, futuro.day));
      expect(item.diasParaVencer, 10);
    });
  });

  group('ItemDespensa.estadoVencimiento', () {
    test('returns sinFecha when no fechaVencimiento', () {
      final item = _makeItem();
      expect(item.estadoVencimiento, EstadoVencimiento.sinFecha);
    });

    test('returns vencido when expired (-1 day)', () {
      final ayer = DateTime.now().subtract(const Duration(days: 1));
      final item = _makeItem(fechaVencimiento: DateTime(ayer.year, ayer.month, ayer.day));
      expect(item.estadoVencimiento, EstadoVencimiento.vencido);
    });

    test('returns urgente for 2 days remaining', () {
      final pronto = DateTime.now().add(const Duration(days: 2));
      final item = _makeItem(fechaVencimiento: DateTime(pronto.year, pronto.month, pronto.day));
      expect(item.estadoVencimiento, EstadoVencimiento.urgente);
    });

    test('returns porVencer for 5 days remaining', () {
      final pronto = DateTime.now().add(const Duration(days: 5));
      final item = _makeItem(fechaVencimiento: DateTime(pronto.year, pronto.month, pronto.day));
      expect(item.estadoVencimiento, EstadoVencimiento.porVencer);
    });

    test('returns ok for 10 days remaining', () {
      final futuro = DateTime.now().add(const Duration(days: 10));
      final item = _makeItem(fechaVencimiento: DateTime(futuro.year, futuro.month, futuro.day));
      expect(item.estadoVencimiento, EstadoVencimiento.ok);
    });
  });

  group('ItemDespensa.venceProximamente', () {
    test('returns true for today (0 days)', () {
      final hoy = DateTime.now();
      final item = _makeItem(fechaVencimiento: DateTime(hoy.year, hoy.month, hoy.day));
      expect(item.venceProximamente, isTrue);
    });

    test('returns true for tomorrow (1 day)', () {
      final manana = DateTime.now().add(const Duration(days: 1));
      final item = _makeItem(fechaVencimiento: DateTime(manana.year, manana.month, manana.day));
      expect(item.venceProximamente, isTrue);
    });

    test('returns false for 2+ days away', () {
      final pasado = DateTime.now().add(const Duration(days: 2));
      final item = _makeItem(fechaVencimiento: DateTime(pasado.year, pasado.month, pasado.day));
      expect(item.venceProximamente, isFalse);
    });

    test('returns false when no fechaVencimiento', () {
      final item = _makeItem();
      expect(item.venceProximamente, isFalse);
    });
  });
}
