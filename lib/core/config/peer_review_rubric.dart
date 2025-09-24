/// Descripciones i18n de la rúbrica de peer review.
/// Estructura: rubricCriteria[criterionKey][score]['es'|'en'] -> String
/// Criterios: punctuality, contributions, commitment, attitude
const Map<String, Map<int, Map<String, String>>> rubricCriteria = {
  'punctuality': {
    2: {'es': 'Frecuentemente tarde', 'en': 'Frequently late'},
    3: {'es': 'Algunas demoras', 'en': 'Some delays'},
    4: {'es': 'Casi siempre puntual', 'en': 'Mostly on time'},
    5: {'es': 'Siempre puntual', 'en': 'Always on time'},
  },
  'contributions': {
    2: {'es': 'Contribuye poco', 'en': 'Contributes little'},
    3: {'es': 'Contribuye moderado', 'en': 'Moderate contribution'},
    4: {'es': 'Contribuye consistentemente', 'en': 'Consistent contribution'},
    5: {
      'es': 'Contribuye de forma sobresaliente',
      'en': 'Outstanding contribution'
    },
  },
  'commitment': {
    2: {'es': 'Compromiso bajo', 'en': 'Low commitment'},
    3: {'es': 'Compromiso aceptable', 'en': 'Acceptable commitment'},
    4: {'es': 'Buen compromiso', 'en': 'Good commitment'},
    5: {'es': 'Compromiso ejemplar', 'en': 'Excellent commitment'},
  },
  'attitude': {
    2: {'es': 'Actitud negativa', 'en': 'Negative attitude'},
    3: {'es': 'Actitud neutra', 'en': 'Neutral attitude'},
    4: {'es': 'Actitud positiva', 'en': 'Positive attitude'},
    5: {'es': 'Actitud sobresaliente', 'en': 'Outstanding attitude'},
  },
};

String rubricLabel(String criterionKey, int score, {String locale = 'es'}) {
  return rubricCriteria[criterionKey]?[score]?[locale] ?? '';
}
