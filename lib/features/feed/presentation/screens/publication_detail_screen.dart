import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';

class PublicationDetailScreen extends StatefulWidget {
  final String id;
  const PublicationDetailScreen({super.key, required this.id});

  @override
  State<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;

  final List<String> _monthNames = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  final List<String> _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Cancha de pasto sintético de última generación, con iluminación LED y camarines. Ideal para partidos y entrenamientos. Disponible todos los días.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      '${_monthNames[DateTime.now().add(Duration(days: _selectedDateIndex)).month - 1]} ${DateTime.now().add(Duration(days: _selectedDateIndex)).year}', 
                      style: const TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 16),
                    _buildDateSelector(),
                    const SizedBox(height: 32),
                    
                    const Text('Horarios disponibles', style: TextStyle(color: Color(0xFF1E70CD), fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildTimeSlots(),
                    const SizedBox(height: 40),
                    
                    CustomButton(
                      text: 'Reservar',
                      onPressed: _selectedTimeIndex != -1 ? () {
                        final dateStr = '${_dayNames[DateTime.now().add(Duration(days: _selectedDateIndex)).weekday - 1]} ${DateTime.now().add(Duration(days: _selectedDateIndex)).day} ${_monthNames[DateTime.now().add(Duration(days: _selectedDateIndex)).month - 1]}';
                        final timeStr = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'][_selectedTimeIndex];
                        final uri = Uri(
                          path: '/publication/${widget.id}/confirm',
                          queryParameters: {
                            'title': 'Cancha de fútbol sintética',
                            'subtitle': 'Club Deportivo Temuco',
                            'date': dateStr,
                            'time': timeStr,
                          },
                        );
                        context.push(uri.toString());
                      } : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, selecciona un horario')),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF1E70CD), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E70CD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            bottom: 16,
            width: 140,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 172,
            top: 32,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cancha de fútbol sintética', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Expanded(child: Text('Club Deportivo Temuco', style: TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Deportes', style: TextStyle(color: Color(0xFF1E70CD), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(14, (index) {
          final date = now.add(Duration(days: index));
          final dayStr = _dayNames[date.weekday - 1];
          final numberStr = date.day.toString();
          
          return _buildDateCircle(
            day: dayStr, 
            number: numberStr, 
            index: index, 
            isSelected: _selectedDateIndex == index
          );
        }),
      ),
    );
  }

  Widget _buildDateCircle({required String day, required String number, required int index, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateIndex = index;
          _selectedTimeIndex = -1; 
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E70CD) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(day, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E70CD), fontSize: 12)),
            const SizedBox(height: 4),
            Text(number, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E70CD), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    final times = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(times.length, (index) {
        final isSelected = _selectedTimeIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E70CD) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade300),
            ),
            child: Text(
              times[index], 
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E70CD), 
                fontWeight: FontWeight.w500
              )
            ),
          ),
        );
      }),
    );
  }
}