import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../publications/domain/entities/availability_config.dart';
import '../../../publications/domain/entities/publication.dart';
import '../../../publications/presentation/providers/my_publications_provider.dart';

class PublicationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const PublicationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState
    extends ConsumerState<PublicationDetailScreen> {
  late DateTime _selectedDate;
  String? _selectedTime;

  final List<String> _weekDays = [
    'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom',
  ];
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  DayOfWeek _dartWeekdayToDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return DayOfWeek.monday;
      case DateTime.tuesday:
        return DayOfWeek.tuesday;
      case DateTime.wednesday:
        return DayOfWeek.wednesday;
      case DateTime.thursday:
        return DayOfWeek.thursday;
      case DateTime.friday:
        return DayOfWeek.friday;
      case DateTime.saturday:
        return DayOfWeek.saturday;
      default:
        return DayOfWeek.sunday;
    }
  }

  List<String> _generateSlots(AvailabilityConfig config, DateTime date) {
    final dayOfWeek = _dartWeekdayToDayOfWeek(date.weekday);
    final hasOverride = config.dayOverrides.any((o) => o.dayOfWeek == dayOfWeek);

    List<DaySchedule> schedules;
    if (hasOverride) {
      final o = config.dayOverrides.firstWhere(
        (o) => o.dayOfWeek == dayOfWeek,
      );
      if (o.isClosed) return [];
      schedules =
          o.schedules.isNotEmpty ? o.schedules : config.defaultSchedules;
    } else {
      schedules = config.defaultSchedules;
    }

    final slots = <String>[];
    for (final schedule in schedules) {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      var startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      while (startMinutes + config.slotDurationMinutes <= endMinutes) {
        final h = startMinutes ~/ 60;
        final m = startMinutes % 60;
        slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
        startMinutes += config.slotDurationMinutes;
      }
    }
    return slots;
  }

  void _handleReservation(
    BuildContext context,
    String title,
    String subtitle,
    AvailabilityConfig availability,
  ) {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un horario')),
      );
      return;
    }

    final dateStr =
        '${_weekDays[_selectedDate.weekday - 1]} ${_selectedDate.day} ${_months[_selectedDate.month - 1]}';
    final endTime = _addMinutes(_selectedTime!, availability.slotDurationMinutes);

    final uri = Uri(
      path: '/publication/${widget.id}/confirm',
      queryParameters: {
        'title': title,
        'subtitle': subtitle,
        'date': dateStr,
        'time': endTime != null ? '$_selectedTime-$endTime' : _selectedTime,
      },
    );
    context.push(uri.toString());
  }

  String? _addMinutes(String time, int minutes) {
    try {
      final parts = time.split(':');
      final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
      final h = total ~/ 60;
      final m = total % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublisher = ref.watch(isPublisherProvider);
    final pubAsync = ref.watch(publicationDetailProvider(widget.id));

    return pubAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E70CD), size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E70CD)),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E70CD), size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar la publicación',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(publicationDetailProvider(widget.id)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (pub) => _buildContent(context, pub, isPublisher),
    );
  }

  Widget _buildContent(BuildContext context, Publication pub, bool isPublisher) {
    final timeSlots = _generateSlots(pub.availability, _selectedDate);

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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1E70CD),
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Detalles Publicación',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
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
                              _buildBlueBanner(pub, isWeb: true),
                              const SizedBox(height: 32),
                              _buildDescription(pub.description),
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
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDateSelector(pub),
                              const SizedBox(height: 32),
                              _buildTimeSelector(timeSlots),
                              const SizedBox(height: 32),
                              _buildActionBox(context, isPublisher, pub),
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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Detalles Publicación',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildBlueBanner(pub, isWeb: false),
                  const SizedBox(height: 16),
                  _buildDescription(pub.description),
                  const SizedBox(height: 24),
                  _buildDateSelector(pub),
                  const SizedBox(height: 24),
                  _buildTimeSelector(timeSlots),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(child: _buildActionBox(context, isPublisher, pub)),
          ),
        );
      },
    );
  }

  Widget _buildBlueBanner(Publication pub, {required bool isWeb}) {
    final categoryLabel = _pubCategoryLabel(pub.category);
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
              image: pub.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(pub.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: pub.imageUrl == null
                ? const Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pub.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 24 : 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pub.ownerName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: isWeb ? 14 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      color: Color(0xFF1E70CD),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  String _pubCategoryLabel(PublicationCategory cat) {
    switch (cat) {
      case PublicationCategory.deporte:
        return 'Deportes';
      case PublicationCategory.eventos:
        return 'Eventos';
      case PublicationCategory.recreacion:
        return 'Recreación';
      case PublicationCategory.otros:
        return 'Otros';
    }
  }

  Widget _buildDescription(String description) {
    return Text(
      description.isNotEmpty
          ? description
          : 'Sin descripción disponible.',
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildDateSelector(Publication pub) {
    final currentMonth = _months[_selectedDate.month - 1];
    final currentYear = _selectedDate.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$currentMonth $currentYear',
          style: const TextStyle(
            color: Color(0xFF1E70CD),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected =
                  date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              final dayName = _weekDays[date.weekday - 1];

              // Check if this day is closed per availability
              final dayOfWeek = _dartWeekdayToDayOfWeek(date.weekday);
              final isClosed = pub.availability.dayOverrides.any(
                (o) => o.dayOfWeek == dayOfWeek && o.isClosed,
              );

              return GestureDetector(
                onTap: isClosed
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = null;
                        });
                      },
                child: Opacity(
                  opacity: isClosed ? 0.4 : 1.0,
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E70CD)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E70CD)
                            : Colors.blue.shade100,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E70CD),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E70CD),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(List<String> slots) {
    if (slots.isEmpty) {
      return const Text(
        'No hay horarios disponibles para este día',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horarios disponibles',
          style: TextStyle(
            color: Color(0xFF1E70CD),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedTime = time);
              },
              child: Container(
                width: 75,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E70CD) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E70CD)
                        : Colors.blue.shade100,
                  ),
                ),
                child: Center(
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1E70CD),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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

  Widget _buildActionBox(
    BuildContext context,
    bool isPublisher,
    Publication pub,
  ) {
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
        onPressed: () => _handleReservation(
          context,
          pub.title,
          pub.ownerName,
          pub.availability,
        ),
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
