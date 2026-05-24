import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyPublicationsScreen extends StatefulWidget {
  const MyPublicationsScreen({super.key});

  @override
  State<MyPublicationsScreen> createState() => _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends State<MyPublicationsScreen> {
  final List<Map<String, dynamic>> _publications = [
    {
      'id': '1',
      'title': 'Cancha de fútbol sintética',
      'subtitle': 'Deporte - Temuco',
      'status': 'Activa',
    },
    {
      'id': '2',
      'title': 'Consultorio de kinesiología',
      'subtitle': 'Salud - Temuco',
      'status': 'Activa',
    },
    {
      'id': '3',
      'title': 'Salon para baile',
      'subtitle': 'Eventos - Temuco',
      'status': 'Pausada',
    },
  ];

  void _toggleStatus(int index) {
    setState(() {
      if (_publications[index]['status'] == 'Activa') {
        _publications[index]['status'] = 'Pausada';
      } else {
        _publications[index]['status'] = 'Activa';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E70CD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mis publicaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publications.length,
        itemBuilder: (context, index) {
          final pub = _publications[index];
          final isActive = pub['status'] == 'Activa';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPublicationCard(
              id: pub['id'],
              title: pub['title'],
              subtitle: pub['subtitle'],
              status: pub['status'],
              statusBg: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
              statusText: isActive ? const Color(0xFF2E7D32) : const Color(0xFF757575),
              onToggleStatus: () => _toggleStatus(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPublicationCard({
    required String id,
    required String title,
    required String subtitle,
    required String status,
    required Color statusBg,
    required Color statusText,
    required VoidCallback onToggleStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(status, style: TextStyle(color: statusText, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/publication/$id/edit'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E70CD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Editar', style: TextStyle(color: Color(0xFF1E70CD), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggleStatus,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(status == 'Activa' ? 'Pausar' : 'Activar', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Eliminar', style: TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}