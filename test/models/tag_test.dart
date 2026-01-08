import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goaly_mobile/models/tag.dart';

void main() {
  group('Tag', () {
    test('creates tag with required fields', () {
      final tag = Tag(
        name: 'Work',
        colorValue: 0xFF5C6BC0,
      );

      expect(tag.name, 'Work');
      expect(tag.colorValue, 0xFF5C6BC0);
      expect(tag.id, isNull);
      expect(tag.createdAt, isNotNull);
    });

    test('color getter returns correct Color', () {
      final tag = Tag(
        name: 'Test',
        colorValue: 0xFF26A69A,
      );

      expect(tag.color, const Color(0xFF26A69A));
    });

    test('toMap converts tag to map correctly', () {
      final now = DateTime.now();
      final tag = Tag(
        id: 1,
        name: 'Personal',
        colorValue: 0xFFEF5350,
        createdAt: now,
      );

      final map = tag.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Personal');
      expect(map['color'], 0xFFEF5350);
      expect(map['created_at'], now.millisecondsSinceEpoch);
    });

    test('fromMap creates tag from map correctly', () {
      final timestamp = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final map = {
        'id': 5,
        'name': 'Urgent',
        'color': 0xFFFF7043,
        'created_at': timestamp,
      };

      final tag = Tag.fromMap(map);

      expect(tag.id, 5);
      expect(tag.name, 'Urgent');
      expect(tag.colorValue, 0xFFFF7043);
      expect(tag.createdAt.millisecondsSinceEpoch, timestamp);
    });

    test('copyWith creates copy with updated fields', () {
      final tag = Tag(
        id: 1,
        name: 'Original',
        colorValue: 0xFF5C6BC0,
      );

      final updated = tag.copyWith(name: 'Updated');

      expect(updated.id, 1);
      expect(updated.name, 'Updated');
      expect(updated.colorValue, 0xFF5C6BC0);
    });

    test('equality compares by id', () {
      final tag1 = Tag(id: 1, name: 'Tag1', colorValue: 0xFF5C6BC0);
      final tag2 = Tag(id: 1, name: 'Different', colorValue: 0xFFEF5350);
      final tag3 = Tag(id: 2, name: 'Tag1', colorValue: 0xFF5C6BC0);

      expect(tag1, equals(tag2)); // Same id
      expect(tag1, isNot(equals(tag3))); // Different id
    });
  });
}
