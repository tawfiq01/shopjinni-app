import 'package:flutter_test/flutter_test.dart';
import 'package:mobishop/features/reports/models/report_models.dart';

void main() {
  group('ImeiHistory.fromJson', () {
    // Laravel's `decimal:2` cast serializes cost fields as JSON strings
    // (e.g. "20000.00"), not numbers. This is the exact shape returned by
    // GET /api/reports/imei-history in production — parsing it used to
    // throw (String is not a subtype of num), which crashed silently and
    // made the report look like it always returned "No unit found".
    test('parses string-typed cost fields from a real API response', () {
      final json = {
        'unit': {
          'id': 9,
          'imei1': '2342423424',
          'imei2': null,
          'status': 'in_stock',
          'is_demo': false,
          'display_name': 'oneplus ce48 12 / 128 (Black)',
          'purchased_at': '2026-10-08',
          'sold_at': null,
          'distributor': 'test',
          'purchase_cost': '20000.00',
        },
        'movements': [
          {
            'date': '2026-10-08 04:01:01',
            'type': 'purchase',
            'branch': 'Main Branch',
            'quantity_change': 1,
            'unit_cost': '20000.00',
          },
        ],
      };

      final history = ImeiHistory.fromJson(json);

      expect(history.purchaseCost, 20000.0);
      expect(history.movements.single.unitCost, 20000.0);
    });

    test('still parses when cost fields arrive as plain numbers', () {
      final json = {
        'unit': {
          'id': 1,
          'imei1': '400000000000001',
          'imei2': null,
          'status': 'sold',
          'is_demo': false,
          'display_name': 'Test Phone',
          'purchased_at': '2026-10-08',
          'sold_at': '2026-10-08',
          'distributor': 'Acme',
          'purchase_cost': 24000,
        },
        'movements': <Map<String, dynamic>>[],
      };

      final history = ImeiHistory.fromJson(json);

      expect(history.purchaseCost, 24000.0);
    });

    test('leaves purchase_cost null for a viewer without reports.view-cost', () {
      final json = {
        'unit': {
          'id': 1,
          'imei1': '400000000000001',
          'imei2': null,
          'status': 'sold',
          'is_demo': false,
          'display_name': 'Test Phone',
          'purchased_at': '2026-10-08',
          'sold_at': null,
          'distributor': 'Acme',
        },
        'movements': <Map<String, dynamic>>[],
      };

      final history = ImeiHistory.fromJson(json);

      expect(history.purchaseCost, isNull);
    });
  });
}
