import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PEDIDOS', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Pendientes'),
          _buildOrderCard(
            title: 'Lasagna Casera',
            author: 'Carlos López',
            price: '10€',
            date: '2026-02-11',
            status: 'Pendiente',
            statusColor: Colors.orange.shade100,
            statusTextColor: Colors.orange.shade800,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Aceptados'),
          _buildOrderCard(
            title: 'Paella Valenciana',
            author: 'María García',
            price: '12€',
            date: '2026-02-10',
            status: 'Aceptado',
            statusColor: Colors.green.shade100,
            statusTextColor: Colors.green.shade800,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Completados'),
          _buildOrderCard(
            title: 'Tarta de Zanahoria',
            author: 'Carlos López',
            price: '15€',
            date: '2026-02-08',
            status: 'Completado',
            statusColor: Colors.grey.shade200,
            statusTextColor: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F4A5B), // Color similar to the dark text in screenshots
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String title,
    required String author,
    required String price,
    required String date,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(author, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
