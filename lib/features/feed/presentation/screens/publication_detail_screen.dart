import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';

class PublicationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const PublicationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends ConsumerState<PublicationDetailScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00'
  ];

  final List<String> _weekDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _handleReservation(BuildContext context) {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un horario')),
      );
      return;
    }

    final dateStr = '${_weekDays[_selectedDate.weekday - 1]} ${_selectedDate.day} ${_months[_selectedDate.month - 1]}';
    
    final uri = Uri(
      path: '/publication/${widget.id}/confirm',
      queryParameters: {
        'title': 'Cancha de fútbol sintética',
        'subtitle': 'Club Deportivo Temuco',
        'date': dateStr,
        'time': _selectedTime,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        if (isWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E70CD), size: 20),
                onPressed: () => context.pop(),
              ),
              title: const Text('Detalles Publicación', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
              centerTitle: false,
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBlueBanner(isWeb: true),
                              const SizedBox(height: 32),
                              _buildDescription(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDateSelector(),
                              const SizedBox(height: 32),
                              _buildTimeSelector(),
                              const SizedBox(height: 32),
                              _buildActionBox(context, isPublisher),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E70CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text('Detalles Publicación', style: TextStyle(color: Colors.grey, fontSize: 16)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildBlueBanner(isWeb: false),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildTimeSelector(),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildActionBox(context, isPublisher),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlueBanner({required bool isWeb}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E70CD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: isWeb ? 150 : 100,
            height: isWeb ? 150 : 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1518605368461-1ee12db89058?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cancha de fútbol sintética',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 24 : 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Club Deportivo Temuco',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: isWeb ? 14 : 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Deportes',
                    style: TextStyle(color: Color(0xFF1E70CD), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Cancha de pasto sintético de última generación, con iluminación LED y camarines. Ideal para partidos y entrenamientos. Disponible todos los días.',
      style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
    );
  }

  Widget _buildDateSelector() {
    final currentMonth = _months[_selectedDate.month - 1];
    final currentYear = _selectedDate.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$currentMonth $currentYear', style: const TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14, 
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
              final dayName = _weekDays[date.weekday - 1];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; 
                  });
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E70CD) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1E70CD) : Colors.blue.shade100,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E70CD),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E70CD),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horarios disponibles', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeSlots.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              child: Container(
                width: 75,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E70CD) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E70CD) : Colors.blue.shade100,
                  ),
                ),
                child: Center(
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E70CD),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionBox(BuildContext context, bool isPublisher) {
    if (isPublisher) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Cambia a modo Solicitante para reservar',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _handleReservation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E70CD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Reservar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}