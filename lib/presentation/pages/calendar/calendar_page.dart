import 'package:flutter/material.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../widgets/bottom_navigation_dock.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime.now();
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  final List<String> weekDays = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // quita el botón de atrás
        title: Text(
          'Calendario',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // header del calendario con navegación
              _buildCalendarHeader(),
              const SizedBox(height: 20),
              // calendario
              _buildCalendar(),
              const SizedBox(height: 30),
              // eventos del día seleccionado
              _buildDayEvents(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationDock(currentIndex: 1),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (selectedMonth == 1) {
                  selectedMonth = 12;
                  selectedYear--;
                } else {
                  selectedMonth--;
                }
              });
            },
            icon: Icon(
              Icons.chevron_left,
              color: AppTheme.goldAccent,
            ),
          ),
          Text(
            '${monthNames[selectedMonth - 1]} $selectedYear',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                if (selectedMonth == 12) {
                  selectedMonth = 1;
                  selectedYear++;
                } else {
                  selectedMonth++;
                }
              });
            },
            icon: Icon(
              Icons.chevron_right,
              color: AppTheme.goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // días de la semana
          Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // días del mes
          ..._buildCalendarWeeks(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarWeeks() {
    List<Widget> weeks = [];
    DateTime firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    int firstWeekday = firstDayOfMonth.weekday;
    int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    // ajustar para que lunes sea 0
    int startOffset = firstWeekday - 1;

    List<Widget> days = [];

    // días vacíos al inicio
    for (int i = 0; i < startOffset; i++) {
      days.add(const Expanded(child: SizedBox()));
    }

    // días del mes
    for (int day = 1; day <= daysInMonth; day++) {
      bool isSelected = day == selectedDate.day &&
          selectedMonth == selectedDate.month &&
          selectedYear == selectedDate.year;
      bool hasEvent = _hasEventOnDay(day);

      days.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = DateTime(selectedYear, selectedMonth, day);
              });
            },
            child: Container(
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.premiumBlack
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.premiumBlack
                            : AppTheme.goldAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      // nueva fila cada 7 días
      if ((startOffset + day) % 7 == 0) {
        weeks.add(
          Row(children: List.from(days)),
        );
        days.clear();
      }
    }

    // completar última fila si es necesario
    if (days.isNotEmpty) {
      while (days.length < 7) {
        days.add(const Expanded(child: SizedBox()));
      }
      weeks.add(Row(children: days));
    }

    return weeks;
  }

  Widget _buildDayEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos del ${selectedDate.day} de ${monthNames[selectedDate.month - 1]}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._getEventsForSelectedDay().map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event['color'].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // indicador de color
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: event['color'],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // información del evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['time'],
                  style: TextStyle(
                    fontSize: 14,
                    color: event['color'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Verifica si un día específico tiene eventos programados (usando datos estáticos)
  bool _hasEventOnDay(int day) {
    final events = _getAllEvents();
    return events.any((event) => event['day'] == day);
  }

  // Obtiene la lista de eventos para el día seleccionado
  List<Map<String, dynamic>> _getEventsForSelectedDay() {
    final events = _getAllEvents();
    return events.where((event) => event['day'] == selectedDate.day).toList();
  }

  // Datos estáticos de eventos para demostración
  List<Map<String, dynamic>> _getAllEvents() {
    return [
      {
        'day': DateTime.now().day,
        'title': 'Clase de Flutter Avanzado',
        'time': '09:00 - 11:00',
        'description': 'Tema: State Management con GetX',
        'color': Colors.blue,
      },
      {
        'day': DateTime.now().day,
        'title': 'Revisión de Proyecto',
        'time': '14:30 - 15:30',
        'description': 'Proyecto final de Bases de Datos',
        'color': Colors.green,
      },
      {
        'day': DateTime.now().day + 1,
        'title': 'Examen de Arquitectura',
        'time': '10:00 - 12:00',
        'description': 'Examen parcial de patrones de diseño',
        'color': Colors.red,
      },
      {
        'day': DateTime.now().day + 2,
        'title': 'Laboratorio de IA',
        'time': '16:00 - 18:00',
        'description': 'Práctica con redes neuronales',
        'color': Colors.orange,
      },
      {
        'day': DateTime.now().day + 5,
        'title': 'Presentación UX/UI',
        'time': '11:00 - 12:00',
        'description': 'Presentación de prototipos',
        'color': Colors.pink,
      },
    ];
  }
}
