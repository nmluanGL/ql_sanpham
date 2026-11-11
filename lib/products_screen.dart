import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'product_form.dart';
import 'product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = ProductService();
  late final Stream<List<Product>> _products = _service.watchProducts();
  String _query = '';
  bool _deleting = false;
  bool _signingOut = false;

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (mounted) _message('Không thể đăng xuất.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _openForm([Product? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductForm(service: _service, product: product),
      ),
    );
    if (mounted && saved == true) {
      _message(product == null ? 'Đã thêm sản phẩm.' : 'Đã lưu thay đổi.');
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Bạn có muốn xóa “${product.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _service.delete(product.id);
      if (mounted) _message('Đã xóa sản phẩm.');
    } catch (_) {
      if (mounted) _message('Không thể xóa sản phẩm.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _buildOverview(
    ThemeData theme,
    List<Product> all,
    int stock,
    int soldOut,
    bool disabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan kho',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final tileWidth = width >= 630 ? (width - 24) / 3 : width;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _Stat(
                    label: 'Mặt hàng',
                    count: all.length,
                    icon: Icons.category_outlined,
                    color: const Color(0xFF3256BB),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _Stat(
                    label: 'Đơn vị tồn kho',
                    count: stock,
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF137362),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _Stat(
                    label: 'Mặt hàng hết kho',
                    count: soldOut,
                    icon: Icons.remove_shopping_cart_outlined,
                    color: const Color(0xFF965216),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Danh sách sản phẩm',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: disabled ? null : () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Tìm theo tên',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (text) =>
              setState(() => _query = text.trim().toLowerCase()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = _deleting || _signingOut;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        leading: Icon(
          Icons.inventory_2_outlined,
          color: theme.colorScheme.primary,
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: disabled ? null : _signOut,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Không tải được danh sách. Kiểm tra mạng và quyền admin.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Lọc danh sách hiển thị. Thống kê vẫn tính trên toàn bộ kho.
          final all = snapshot.data!;
          final visible = all
              .where((product) => product.name.toLowerCase().contains(_query))
              .toList();
          final stock = all.fold<int>(
            0,
            (total, product) => total + product.quantity,
          );
          final soldOut = all.where((product) => product.quantity == 0).length;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildOverview(
                        theme,
                        all,
                        stock,
                        soldOut,
                        disabled,
                      ),
                    ),
                  ),
                  if (visible.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Chưa có sản phẩm.'
                                : 'Không tìm thấy sản phẩm.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 370,
                              mainAxisExtent: 224,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final product = visible[index];
                          return _ProductCard(
                            product: product,
                            enabled: !disabled,
                            onEdit: () => _openForm(product),
                            onDelete: () => _delete(product),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
                Text(label),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

enum _ProductAction { edit, delete }

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFFEAF0FD),
                  child: Center(
                    child: ProductImage(url: product.image, size: 112),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: PopupMenuButton<_ProductAction>(
                      enabled: enabled,
                      tooltip: 'Thao tác sản phẩm',
                      onSelected: (action) {
                        switch (action) {
                          case _ProductAction.edit:
                            onEdit();
                          case _ProductAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _ProductAction.edit,
                          child: Text('Sửa sản phẩm'),
                        ),
                        PopupMenuItem(
                          value: _ProductAction.delete,
                          child: Text('Xóa sản phẩm'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${product.price} đ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                Text(
                  product.quantity == 0
                      ? 'Hết hàng'
                      : 'Tồn kho: ${product.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
