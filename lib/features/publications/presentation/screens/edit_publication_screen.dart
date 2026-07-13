import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../publications/domain/entities/availability_config.dart';
import '../../../publications/domain/entities/publication.dart';
import '../../../publications/domain/usecases/update_publication_usecase.dart';
import '../providers/my_publications_provider.dart';

String _catToString(PublicationCategory cat) => switch (cat) {
  PublicationCategory.deporte => 'Deporte',
  PublicationCategory.eventos => 'Eventos',
  PublicationCategory.recreacion => 'Recreación',
  PublicationCategory.otros => 'Otros',
};

class EditPublicationScreen extends ConsumerStatefulWidget {
  final String id;
  const EditPublicationScreen({super.key, required this.id});

  @override
  ConsumerState<EditPublicationScreen> createState() =>
      _EditPublicationScreenState();
}

class _EditPublicationScreenState extends ConsumerState<EditPublicationScreen> {
  int _selectedDuration = 60;
  bool _sameSchedule = true;
  bool _initialized = false;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _catController;
  late TextEditingController _urlController;
  late TextEditingController _regionController;

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
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _catController = TextEditingController();
    _urlController = TextEditingController();
    _regionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _catController.dispose();
    _urlController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  PublicationCategory _parseCategory(String raw) {
    switch (raw.toLowerCase().trim()) {
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

  AvailabilityConfig _buildAvailability() {
    final dayNames = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final dayEnums = [
      DayOfWeek.monday,
      DayOfWeek.tuesday,
      DayOfWeek.wednesday,
      DayOfWeek.thursday,
      DayOfWeek.friday,
      DayOfWeek.saturday,
      DayOfWeek.sunday,
    ];
    final overrides = <DayOverride>[];
    for (var i = 0; i < _days.length; i++) {
      final day = _days[i];
      final idx = dayNames.indexOf(day['name'] as String);
      if (idx < 0) continue;
      overrides.add(
        DayOverride(
          dayOfWeek: dayEnums[idx],
          isClosed: day['disabled'] as bool,
          schedules: (day['disabled'] as bool)
              ? []
              : [
                  DaySchedule(
                    startTime: day['start'] as String,
                    endTime: day['end'] as String,
                  ),
                ],
        ),
      );
    }
    return AvailabilityConfig(
      slotDurationMinutes: _selectedDuration,
      sameScheduleAllDays: _sameSchedule,
      defaultSchedules:
          _sameSchedule && overrides.isNotEmpty && !overrides.first.isClosed
          ? overrides.first.schedules
          : [],
      dayOverrides: overrides,
    );
  }

  /// No hay `setState`/`finally` local para el estado de guardado: el botón
  /// se deshabilita observando directamente `publicationFormNotifierProvider`
  /// (ver [build]), que ya queda en loading mientras esta llamada está en
  /// vuelo. Evita la carrera de doble tap que producía publicaciones
  /// duplicadas en el smoke test.
  Future<void> _handleSave() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    try {
      await ref
          .read(publicationFormNotifierProvider.notifier)
          .edit(
            id: widget.id,
            params: UpdatePublicationParams(
              title: title,
              description: _descController.text.trim(),
              category: _parseCategory(_catController.text),
              region: _regionController.text.trim(),
              availability: _buildAvailability(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación actualizada')),
        );
        context.go('/my-publications');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la publicación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);
    final isSaving = ref.watch(publicationFormNotifierProvider).isLoading;

    // Pre-fill controllers with real publication data on first load
    ref.watch(publicationDetailProvider(widget.id)).whenData((pub) {
      if (_initialized) return;
      _initialized = true;
      _nameController.text = pub.title;
      _descController.text = pub.description;
      _catController.text = _catToString(pub.category);
      _urlController.text = pub.imageUrl ?? '';
      _regionController.text = pub.region;
      _selectedDuration = pub.availability.slotDurationMinutes;
      _sameSchedule = pub.availability.sameScheduleAllDays;
    });

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
                      _buildWebHeader(context, 'Editar publicación'),
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
                                child: _buildForm(isSaving),
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
              'Editar publicación',
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
            child: _buildForm(isSaving),
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

  Widget _buildForm(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Editar publicación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Nombre del servicio', _nameController),
        const SizedBox(height: 16),
        _buildTextField('Descripción', _descController, maxLines: 4),
        const SizedBox(height: 16),
        _buildTextField('Categoría', _catController),
        const SizedBox(height: 16),
        _buildTextField('Imagen (URL)', _urlController),
        const SizedBox(height: 16),
        _buildTextField('Región', _regionController),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horario para todos los días',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '09:00',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hasta',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '18:00',
                          style: TextStyle(fontSize: 14),
                        ),
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
          text: 'Guardar cambios',
          loading: isSaving,
          onPressed: isSaving ? null : _handleSave,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E70CD)),
            ),
          ),
        ),
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
