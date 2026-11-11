import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'cloudinary_image_upload.dart';
import 'product_service.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        semanticLabel: 'Không tải được ảnh',
      ),
    ),
  );
}

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, required this.service, this.product});

  final ProductService service;
  final Product? product;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final _quantity = TextEditingController(
    text: widget.product?.quantity.toString(),
  );
  late final _imageUrl = TextEditingController(text: widget.product?.image);
  XFile? _selectedImage;
  Uint8List? _preview;
  bool _picking = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    if (_picking || _saving) return;
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      if (await image.length() > 5 * 1024 * 1024) {
        if (mounted) _message('Chọn ảnh có dung lượng tối đa 5 MB.');
        return;
      }
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImage = image;
          _preview = bytes;
        });
      }
    } catch (_) {
      if (mounted) _message('Không mở được ảnh từ máy.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  num? _readPrice(String text) =>
      num.tryParse(text.trim().replaceAll(',', '.'));

  // Nếu chọn ảnh mới, lấy URL từ Cloudinary trước khi lưu sản phẩm.
  Future<bool> _uploadSelectedImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return true;

    try {
      final url = await CloudinaryImageUpload.upload(selectedImage)
          .timeout(const Duration(seconds: 45));
      if (!mounted) return false;

      setState(() {
        _imageUrl.text = url;
        _selectedImage = null;
        _preview = null;
      });
      return true;
    } catch (_) {
      if (mounted) {
        _message('Tải ảnh thất bại. Kiểm tra Cloudinary và thử lại.');
      }
      return false;
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_selectedImage != null) {
        final uploaded = await _uploadSelectedImage();
        if (!uploaded || !mounted) return;
      }

      await widget.service.save(
        existing: widget.product,
        name: _name.text.trim(),
        price: _readPrice(_price.text)!,
        quantity: int.parse(_quantity.text.trim()),
        imageUrl: _imageUrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'permission-denied' => 'Tài khoản không có quyền lưu sản phẩm.',
        _ => 'Không lưu được sản phẩm. Kiểm tra kết nối và cấu hình Firebase.',
      };
      _message(message);
    } catch (_) {
      if (mounted) _message('Không lưu được sản phẩm.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildImageUrlField() => TextFormField(
    enabled: !_saving && _selectedImage == null,
    controller: _imageUrl,
    keyboardType: TextInputType.url,
    decoration: const InputDecoration(
      labelText: 'Link ảnh',
      hintText: 'https://example.com/anh.jpg',
    ),
    validator: (value) {
      if (_selectedImage != null) return null;
      final text = value!.trim();
      if (text.isEmpty) return 'Nhập link ảnh sản phẩm.';
      final url = Uri.tryParse(text);
      if (url == null ||
          url.scheme != 'https' ||
          url.host.isEmpty ||
          RegExp(r'\s').hasMatch(text)) {
        return 'Nhập link ảnh HTTPS hợp lệ.';
      }
      return null;
    },
  );

  Widget _buildNameField() => TextFormField(
    enabled: !_saving,
    controller: _name,
    decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
    validator: (value) => value!.trim().isEmpty ? 'Nhập tên sản phẩm.' : null,
  );

  Widget _buildPriceField() => TextFormField(
    enabled: !_saving,
    controller: _price,
    decoration: const InputDecoration(labelText: 'Giá'),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) {
      final price = _readPrice(value!);
      return price == null || !price.isFinite || price < 0
          ? 'Nhập giá là số không âm.'
          : null;
    },
  );

  Widget _buildQuantityField() => TextFormField(
    enabled: !_saving,
    controller: _quantity,
    decoration: const InputDecoration(labelText: 'Số lượng'),
    keyboardType: TextInputType.number,
    validator: (value) {
      final text = value!.trim();
      final quantity = int.tryParse(text);
      return !RegExp(r'^\d+$').hasMatch(text) ||
              quantity == null ||
              quantity < 0 ||
              quantity > 9007199254740991
          ? 'Nhập số lượng là số nguyên không âm hợp lệ.'
          : null;
    },
  );

  Widget _buildImageTile(BuildContext context) {
    const size = 144.0;
    final colors = Theme.of(context).colorScheme;
    final preview = _preview;
    final currentImage = widget.product?.image;
    final hasImage = preview != null || currentImage != null;

    return SizedBox.square(
      dimension: size,
      child: OutlinedButton(
        onPressed: _saving || _picking ? null : _pickImage,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.primaryContainer.withValues(alpha: 0.3),
          side: BorderSide(color: colors.outlineVariant),
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (preview != null)
              Image.memory(preview, fit: BoxFit.contain)
            else if (currentImage != null)
              ProductImage(url: currentImage, size: size)
            else
              const Center(
                child: Icon(Icons.add_photo_alternate_outlined, size: 36),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(hasImage ? 'Đổi ảnh' : 'Thêm ảnh'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (CloudinaryImageUpload.isConfigured)
                  Center(child: _buildImageTile(context)),
                const SizedBox(height: 8),
                _buildImageUrlField(),
                const SizedBox(height: 12),
                _buildNameField(),
                const SizedBox(height: 12),
                _buildPriceField(),
                const SizedBox(height: 12),
                _buildQuantityField(),
                if (_selectedImage != null)
                  ListTile(
                    title: Text(_selectedImage!.name),
                    trailing: IconButton(
                      tooltip: 'Bỏ ảnh đã chọn',
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _selectedImage = null;
                              _preview = null;
                            }),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving || _picking ? null : _save,
                  child: Text(_saving ? 'Đang lưu…' : 'Lưu sản phẩm'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
