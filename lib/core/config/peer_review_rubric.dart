


const Map<String, Map<int, String>> rubricCriteria = {
  'punctuality': {
    2: 'Llegó tarde o faltó a la mayoría de sesiones, afectando al equipo.',
    3: 'Llegó tarde con frecuencia o se ausentó en varias ocasiones.',
    4: 'Fue puntual casi siempre y asistió a la mayoría de sesiones.',
    5: 'Llegó puntualmente a todas las reuniones del equipo.',
  },
  'contributions': {
    2: 'Se mantuvo pasivo y casi no aportó ideas ni trabajo al equipo.',
    3: 'Participó de forma esporádica en discusiones o tareas compartidas.',
    4: 'Realizó varios aportes útiles, aunque podría ser más propositivo.',
    5: 'Sus aportes fueron constantes y enriquecieron el trabajo del equipo.',
  },
  'commitment': {
    2: 'Mostró poco compromiso con las tareas o roles asignados al equipo.',
    3: 'A veces bajó su compromiso y eso retrasó el avance del equipo.',
    4: 'Asumió responsabilidades la mayor parte del tiempo, podría aportar más.',
    5: 'Se mantuvo siempre comprometido con las tareas y roles del equipo.',
  },
  'attitude': {
    2: 'Mostró una actitud negativa o indiferente hacia el trabajo del equipo.',
    3: 'A veces tuvo buena actitud, pero no suficiente para impactar al equipo.',
    4: 'Generalmente mantuvo una actitud abierta y positiva que ayudó al equipo.',
    5: 'Siempre mostró actitud positiva y disposición para aportar con calidad.',
  },
};

String rubricLabel(String criterionKey, int score) {
  return rubricCriteria[criterionKey]?[score] ?? '';
}
