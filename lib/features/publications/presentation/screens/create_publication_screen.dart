import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() => _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  int _selectedDuration = 30;
  bool _sameSchedule = true;

  final List<Map<String, dynamic>> _days = [
    {'name': 'Lunes', 'disabled': false, 'start': '09:00', 'end': '18:00'},
    {'name': 'Martes', 'disabled': false, 'start': '09:00', 'end': '18:00'},
    {'name': 'Miércoles', 'disabled': false, 'start': '09:00', 'end': '18:00'},
    {'name': 'Jueves', 'disabled': false, 'start': '09:00', 'end': '18:00'},
    {'name': 'Viernes', 'disabled': false, 'start': '09:00', 'end': '18:00'},
    {'name': 'Sábado', 'disabled': false, 'start': '09:00', 'end': '14:00'},
    {'name': 'Domingo', 'disabled': true, 'start': '09:00', 'end': '14:00'},
  ];

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
        title: const Text('Nueva publicación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear publicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            const CustomTextField(label: 'Nombre del servicio', hintText: 'Ej: Cancha de fútbol'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Descripción', hintText: 'Describe el espacio o servicio...'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Categoría', hintText: 'Deporte'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Imagen (URL)', hintText: 'https://...'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Región', hintText: 'Temuco'),
            const SizedBox(height: 32),
            Container(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text('Agenda Inteligente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E70CD))),
            const SizedBox(height: 16),
            const Text('Duración de cada slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDurationOption(30),
                const SizedBox(width: 12),
                _buildDurationOption(60),
                const SizedBox(width: 12),
                _buildDurationOption(90),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildScheduleTypeOption('Mismo horario todos los días', true),
                const SizedBox(width: 12),
                _buildScheduleTypeOption('Personalizar por día', false),
              ],
            ),
            const SizedBox(height: 16),
            if (_sameSchedule)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Horario para todos los días', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: const Text('09:00', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('hasta', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: const Text('18:00', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: List.generate(_days.length, (index) {
                    final day = _days[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: day['disabled'],
                              activeColor: const Color(0xFF1E70CD),
                              onChanged: (val) {
                                setState(() {
                                  _days[index]['disabled'] = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              day['name'],
                              style: TextStyle(
                                color: day['disabled'] ? Colors.grey : const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                color: day['disabled'] ? Colors.grey.shade100 : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day['start'],
                                style: TextStyle(
                                  color: day['disabled'] ? Colors.grey : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('hasta', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                color: day['disabled'] ? Colors.grey.shade100 : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day['end'],
                                style: TextStyle(
                                  color: day['disabled'] ? Colors.grey : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            const SizedBox(height: 32),
            CustomButton(text: 'Guardar publicación', onPressed: () => context.pop()),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(int minutes) {
    final isSelected = _selectedDuration == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = minutes),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF1E70CD) : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              '$minutes min',
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E70CD) : const Color(0xFF1E293B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTypeOption(String text, bool isSame) {
    final isSelected = _sameSchedule == isSame;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sameSchedule = isSame),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E70CD) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}