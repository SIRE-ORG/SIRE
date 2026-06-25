import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/availability_config.dart';
import '../../domain/entities/publication.dart';
import '../../domain/usecases/create_publication_usecase.dart';
import '../providers/my_publications_provider.dart';

class CreatePublicationScreen extends ConsumerStatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  ConsumerState<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState
    extends ConsumerState<CreatePublicationScreen> {
  int _selectedDuration = 30;
  bool _sameSchedule = true;
  bool _guardando = false;

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

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
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _categoriaCtrl.dispose();
    _imagenCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  PublicationCategory _parseCat(String s) {
    switch (s.trim().toLowerCase()) {
      case 'deporte':
        return PublicationCategory.deporte;
      case 'eventos':
        return PublicationCategory.eventos;
      case 'recreacion':
      case 'recreación':
        return PublicationCategory.recreacion;
      default:
        return PublicationCategory.otros;
    }
  }

  Future<void> _guardar() async {
    final params = CreatePublicationParams(
      title: _nombreCtrl.text.trim(),
      description: _descripcionCtrl.text.trim(),
      category: _parseCat(_categoriaCtrl.text),
      region: _regionCtrl.text.trim(),
      availability: const AvailabilityConfig(
        slotDurationMinutes: 60,
        sameScheduleAllDays: true,
        defaultSchedules: [DaySchedule(startTime: '09:00', endTime: '18:00')],
        dayOverrides: [
          DayOverride(
            dayOfWeek: DayOfWeek.sunday,
            isClosed: true,
            schedules: [],
          ),
        ],
      ),
    );

    setState(() => _guardando = true);
    try {
      await ref
          .read(publicationFormNotifierProvider.notifier)
          .create(params: params);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación creada')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo crear: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
            body: Row(
              children: [
                _buildSidebar(context, isPublisher),
                Expanded(
                  child: Column(
                    children: [
                      _buildWebHeader(context, 'Nueva publicación'),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _buildForm(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E70CD),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Nueva publicación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildForm(),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, bool isPublisher) {
    return Container(
      width: 250,
      color: const Color(0xFF1E70CD),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            'SIRE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(
            context,
            Icons.home_outlined,
            'Inicio',
            () => context.go('/feed'),
          ),
          if (!isPublisher)
            _buildSidebarItem(
              context,
              Icons.calendar_today_outlined,
              'Mis Reservas',
              () => context.go('/my-reservations'),
            )
          else
            _buildSidebarItem(
              context,
              Icons.bar_chart_outlined,
              'Dashboard',
              () => context.go('/dashboard'),
              isActive: true,
            ),
          _buildSidebarItem(
            context,
            Icons.person_outline,
            'Perfil',
            () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }

  Widget _buildWebHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1E70CD),
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E70CD),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crear publicación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Nombre del servicio',
          hintText: 'Ej: Cancha de fútbol',
          controller: _nombreCtrl,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Descripción',
          hintText: 'Describe el espacio o servicio...',
          controller: _descripcionCtrl,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Categoría',
          hintText: 'Deporte',
          controller: _categoriaCtrl,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Imagen (URL)',
          hintText: 'https://...',
          controller: _imagenCtrl,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Región',
          hintText: 'Temuco',
          controller: _regionCtrl,
        ),
        const SizedBox(height: 32),
        Container(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 24),
        const Text(
          'Agenda Inteligente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E70CD),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Duración de cada slot',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horario para todos los días',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _TimeDisplay(text: '09:00')),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hasta',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: _TimeDisplay(text: '18:00')),
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
                            color: day['disabled']
                                ? Colors.grey
                                : const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: day['disabled']
                                ? Colors.grey.shade100
                                : Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day['start'],
                            style: TextStyle(
                              color: day['disabled']
                                  ? Colors.grey
                                  : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'hasta',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: day['disabled']
                                ? Colors.grey.shade100
                                : Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day['end'],
                            style: TextStyle(
                              color: day['disabled']
                                  ? Colors.grey
                                  : Colors.black,
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
        CustomButton(
          text: _guardando ? 'Guardando...' : 'Guardar publicación',
          onPressed: () {
            if (!_guardando) _guardar();
          },
        ),
        const SizedBox(height: 40),
      ],
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
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E70CD)
                  : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              '$minutes min',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1E70CD)
                    : const Color(0xFF1E293B),
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
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
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

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
