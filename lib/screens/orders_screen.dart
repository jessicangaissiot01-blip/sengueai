import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Onglet Commandes, avec deux parties :
 *  - Mes achats : les commandes que l'utilisateur a passées, et leur statut ;
 *  - Commandes reçues : les commandes faites à sa boutique. Le vendeur peut
 *    les accepter, les refuser, puis les marquer comme livrées.
 */
class OrdersScreen extends StatefulWidget {
  final User user;
  final bool hasShop;

  const OrdersScreen({super.key, required this.user, required this.hasShop});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _database = DatabaseService();
  late final Stream<List<ShopOrder>> _purchases = _database.watchPurchases(widget.user.uid);
  late final Stream<List<ShopOrder>> _sales = _database.watchSales(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    // DefaultTabController gère les deux onglets du haut.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('orders')),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: tr('myPurchases')),
              Tab(text: tr('receivedOrders')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_purchases, asSeller: false),
            widget.hasShop
                ? _buildList(_sales, asSeller: true)
                : Center(child: Text(tr('noShopForOrders'), textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Stream<List<ShopOrder>> stream, {required bool asSeller}) {
    return StreamBuilder<List<ShopOrder>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(tr('errorUnknown')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return Center(child: Text(asSeller ? tr('noSales') : tr('noPurchases')));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderCard(orders[index], asSeller: asSeller),
        );
      },
    );
  }

  Widget _buildOrderCard(ShopOrder order, {required bool asSeller}) {
    // La photo du produit est gardée dans la commande, en base64.
    Uint8List? image;
    try {
      if (order.productImage.isNotEmpty) image = base64Decode(order.productImage);
    } catch (_) {
      image = null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image == null
                      ? Container(width: 56, height: 56, color: AppColors.lightGreen)
                      : Image.memory(image, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${order.quantity} x ${formatPrice(order.price)}'),
                      Text(
                        '${tr('total')} : ${formatPrice(order.total)}',
                        style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            // L'acheteur voit la boutique ; le vendeur voit qui a commandé.
            if (asSeller) ...[
              Text('${tr('buyer')} : ${order.buyerName}'),
              Text('${tr('phone')} : ${order.buyerPhone}'),
            ] else
              Text('${tr('shop')} : ${order.shopName}'),
            if (order.note.isNotEmpty) Text('${tr('message')} : ${order.note}'),
            if (asSeller) _buildSellerActions(order),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.blue;
        break;
      case 'delivered':
        color = AppColors.green;
        break;
      case 'refused':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Chip(
      label: Text(tr('status_$status'), style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  /*
   * Boutons du vendeur selon l'état de la commande :
   *  - en attente : Refuser ou Accepter ;
   *  - acceptée   : Marquer comme livrée (le stock baisse) ;
   *  - livrée ou refusée : plus rien à faire.
   * Le bouton "copier" met le numéro de l'acheteur dans le presse-papiers.
   */
  Widget _buildSellerActions(ShopOrder order) {
    final buttons = <Widget>[
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: order.buyerPhone));
          if (mounted) showMessage(context, tr('phoneCopied'));
        },
        icon: const Icon(Icons.copy, size: 18),
        label: Text(tr('copyPhone')),
      ),
    ];

    if (order.status == 'pending') {
      buttons.addAll([
        TextButton(
          onPressed: () => _database.updateOrderStatus(order, 'refused'),
          child: Text(tr('refuse'), style: const TextStyle(color: Colors.red)),
        ),
        FilledButton(
          onPressed: () => _database.updateOrderStatus(order, 'accepted'),
          child: Text(tr('accept')),
        ),
      ]);
    } else if (order.status == 'accepted') {
      buttons.add(FilledButton(
        onPressed: () => _database.updateOrderStatus(order, 'delivered'),
        child: Text(tr('markDelivered')),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: buttons,
      ),
    );
  }
}
