import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ql_sanpham/login_screen.dart';
import 'package:ql_sanpham/product_form.dart';
import 'package:ql_sanpham/product_service.dart';

void main() {
  testWidgets('Đăng nhập yêu cầu email và mật khẩu', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();

    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsOneWidget);
  });

  testWidgets('Form từ chối dữ liệu sai và yêu cầu link ảnh khi thêm', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProductForm(service: ProductService())),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '   ');
    await tester.enterText(fields.at(2), '-1');
    await tester.enterText(fields.at(3), '1.5');
    await tester.ensureVisible(find.text('Lưu sản phẩm'));
    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pump();

    expect(find.text('Nhập tên sản phẩm.'), findsOneWidget);
    expect(find.text('Nhập giá là số không âm.'), findsOneWidget);
    expect(
      find.text('Nhập số lượng là số nguyên không âm hợp lệ.'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(1), 'Sổ tay');
    await tester.enterText(fields.at(2), '0');
    await tester.enterText(fields.at(3), '0');
    await tester.ensureVisible(find.text('Lưu sản phẩm'));
    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập link ảnh sản phẩm.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'file:///anh.jpg');
    await tester.ensureVisible(find.text('Lưu sản phẩm'));
    await tester.tap(find.text('Lưu sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập link ảnh HTTPS hợp lệ.'), findsOneWidget);
  });
}
