import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/models/transfer_file_item.dart';

void main() {
  TransferFileItem item(String filePath, String name) =>
      TransferFileItem(file: File(filePath), transferName: name);

  List<String> names(List<TransferFileItem> items) =>
      items.map((i) => i.transferName).toList();

  test('numbers files that share a name but are different files', () {
    final result = TransferFileItem.withUniqueNames([
      item('/a/photo.jpg', 'photo.jpg'),
      item('/b/photo.jpg', 'photo.jpg'),
      item('/c/photo.jpg', 'photo.jpg'),
    ]);

    expect(names(result), ['photo.jpg', 'photo (2).jpg', 'photo (3).jpg']);
    expect(result[1].file.path, '/b/photo.jpg');
  });

  test('checks new picks against what is already selected', () {
    final existing = [item('/a/report.pdf', 'report.pdf')];

    final result = TransferFileItem.withUniqueNames([
      item('/b/report.pdf', 'report.pdf'),
    ], existing: existing);

    expect(names(result), ['report (2).pdf']);
  });

  test('treats names differing only in case as the same name', () {
    final result = TransferFileItem.withUniqueNames([
      item('/a/A.txt', 'A.txt'),
      item('/b/a.txt', 'a.txt'),
    ]);

    expect(names(result), ['A.txt', 'a (2).txt']);
  });

  test('keeps the folder part of a nested name', () {
    final result = TransferFileItem.withUniqueNames([
      item('/x/docs/readme', 'docs/readme'),
      item('/y/docs/readme', 'docs/readme'),
    ]);

    expect(names(result), ['docs/readme', 'docs/readme (2)']);
  });

  test('skips a number that is itself already taken', () {
    final result = TransferFileItem.withUniqueNames([
      item('/a/x.bin', 'x.bin'),
      item('/b/x (2).bin', 'x (2).bin'),
      item('/c/x.bin', 'x.bin'),
    ]);

    expect(names(result), ['x.bin', 'x (2).bin', 'x (3).bin']);
  });

  test('the same file picked twice is only sent once', () {
    final existing = [item('/a/song.mp3', 'song.mp3')];

    final result = TransferFileItem.withUniqueNames([
      item('/a/song.mp3', 'song.mp3'),
      item('/a/other.mp3', 'other.mp3'),
      item('/a/other.mp3', 'other.mp3'),
    ], existing: existing);

    expect(names(result), ['other.mp3']);
  });

  test('leaves already distinct names untouched', () {
    final input = [item('/a/1.txt', '1.txt'), item('/a/2.txt', '2.txt')];

    final result = TransferFileItem.withUniqueNames(input);

    expect(identical(result[0], input[0]), isTrue);
    expect(identical(result[1], input[1]), isTrue);
  });
}
