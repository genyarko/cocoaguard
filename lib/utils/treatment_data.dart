import '../services/knowledge_service.dart';

// ── English (default) ────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> leafTreatments = {
  'anthracnose': {
    'name': 'Anthracnose (Black Pod)',
    'severity': 'moderate',
    'recommendations': [
      'Remove and destroy infected pods immediately',
      'Apply copper-based fungicide (e.g., Bordeaux mixture)',
      'Improve canopy aeration by pruning',
      'Harvest ripe pods promptly to reduce spread',
    ],
  },
  'cssvd': {
    'name': 'Cocoa Swollen Shoot Virus Disease',
    'severity': 'severe',
    'recommendations': [
      'Remove infected trees and surrounding contact trees',
      'Report to local COCOBOD extension officer',
      'Replant with CSSVD-tolerant varieties',
      'Control mealybug vectors with approved insecticides',
    ],
  },
  'healthy': {
    'name': 'Healthy Pod',
    'severity': 'none',
    'recommendations': [
      'Continue regular maintenance and monitoring',
      'Maintain shade tree management',
      'Apply fertilizer per schedule',
    ],
  },
};

const Map<String, Map<String, dynamic>> podTreatments = {
  'carmenta': {
    'name': 'Carmenta Pod Borer',
    'severity': 'moderate',
    'recommendations': [
      'Remove and destroy infested pods promptly',
      'Apply approved insecticides (e.g., cypermethrin) at borer flight peaks',
      'Harvest early to reduce borer population buildup',
      'Use pheromone traps to monitor adult borer activity',
    ],
  },
  'moniliasis': {
    'name': 'Frosty Pod Rot (Moniliasis)',
    'severity': 'severe',
    'recommendations': [
      'Remove all infected pods and bury or burn them immediately',
      'Apply copper-based fungicides every 2–3 weeks during wet season',
      'Prune to improve air circulation and reduce humidity',
      'Harvest all ripe and near-ripe pods to limit spread',
    ],
  },
  'phytophthora': {
    'name': 'Black Pod Rot (Phytophthora)',
    'severity': 'severe',
    'recommendations': [
      'Remove infected pods immediately and destroy them away from the farm',
      'Apply Ridomil or copper-based fungicide every 2 weeks',
      'Clear ground litter to reduce soil splash inoculum',
      'Use resistant planting materials where available',
    ],
  },
  'witches_broom': {
    'name': "Witches' Broom Disease",
    'severity': 'severe',
    'recommendations': [
      'Remove and burn all brooms and diseased pods promptly',
      'Apply copper oxychloride fungicide after pruning',
      'Replant with resistant varieties where possible',
      'Report severe outbreaks to local COCOBOD extension officer',
    ],
  },
  'healthy': {
    'name': 'Healthy Pod',
    'severity': 'none',
    'recommendations': [
      'Continue regular maintenance and monitoring',
      'Harvest pods at optimal ripeness',
      'Maintain shade tree management for canopy health',
    ],
  },
};

// ── French ────────────────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> _leafTreatmentsFr = {
  'anthracnose': {
    'severity': 'modéré',
    'recommendations': [
      'Retirer et détruire immédiatement les cabosses infectées',
      'Appliquer un fongicide à base de cuivre (ex. bouillie bordelaise)',
      'Améliorer l\'aération du couvert par la taille',
      'Récolter rapidement les cabosses mûres pour limiter la propagation',
    ],
  },
  'cssvd': {
    'severity': 'grave',
    'recommendations': [
      'Arracher les arbres infectés et les arbres de contact environnants',
      'Signaler à l\'agent de vulgarisation COCOBOD local',
      'Replanter avec des variétés tolérantes au CSSVD',
      'Lutter contre les cochenilles vectrices avec des insecticides approuvés',
    ],
  },
  'healthy': {
    'severity': 'aucune',
    'recommendations': [
      'Continuer l\'entretien régulier et la surveillance',
      'Maintenir la gestion des arbres d\'ombrage',
      'Appliquer l\'engrais selon le calendrier',
    ],
  },
};

const Map<String, Map<String, dynamic>> _podTreatmentsFr = {
  'carmenta': {
    'severity': 'modéré',
    'recommendations': [
      'Retirer et détruire rapidement les cabosses infestées',
      'Appliquer des insecticides approuvés (ex. cyperméthrine) lors des pics de vol',
      'Récolter tôt pour réduire l\'accumulation de foreurs',
      'Utiliser des pièges à phéromones pour surveiller l\'activité des adultes',
    ],
  },
  'moniliasis': {
    'severity': 'grave',
    'recommendations': [
      'Retirer toutes les cabosses infectées et les enterrer ou brûler immédiatement',
      'Appliquer des fongicides à base de cuivre toutes les 2–3 semaines en saison des pluies',
      'Tailler pour améliorer la circulation de l\'air et réduire l\'humidité',
      'Récolter toutes les cabosses mûres et presque mûres pour limiter la propagation',
    ],
  },
  'phytophthora': {
    'severity': 'grave',
    'recommendations': [
      'Retirer immédiatement les cabosses infectées et les détruire loin de la plantation',
      'Appliquer du Ridomil ou un fongicide à base de cuivre toutes les 2 semaines',
      'Nettoyer la litière au sol pour réduire l\'inoculum par éclaboussure',
      'Utiliser des matériaux de plantation résistants si disponibles',
    ],
  },
  'witches_broom': {
    'severity': 'grave',
    'recommendations': [
      'Retirer et brûler tous les balais et cabosses malades rapidement',
      'Appliquer un fongicide à l\'oxychlorure de cuivre après la taille',
      'Replanter avec des variétés résistantes si possible',
      'Signaler les épidémies graves à l\'agent de vulgarisation COCOBOD local',
    ],
  },
  'healthy': {
    'severity': 'aucune',
    'recommendations': [
      'Continuer l\'entretien régulier et la surveillance',
      'Récolter les cabosses à maturité optimale',
      'Maintenir la gestion des arbres d\'ombrage pour la santé du couvert',
    ],
  },
};

// ── Spanish ───────────────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> _leafTreatmentsEs = {
  'anthracnose': {
    'severity': 'moderada',
    'recommendations': [
      'Retirar y destruir las mazorcas infectadas inmediatamente',
      'Aplicar fungicida a base de cobre (ej. caldo bordelés)',
      'Mejorar la aireación del dosel mediante la poda',
      'Cosechar las mazorcas maduras rápidamente para reducir la propagación',
    ],
  },
  'cssvd': {
    'severity': 'grave',
    'recommendations': [
      'Eliminar los árboles infectados y los árboles de contacto circundantes',
      'Reportar al extensionista local de COCOBOD',
      'Replantar con variedades tolerantes al CSSVD',
      'Controlar los vectores de cochinilla con insecticidas aprobados',
    ],
  },
  'healthy': {
    'severity': 'ninguna',
    'recommendations': [
      'Continuar el mantenimiento regular y el monitoreo',
      'Mantener el manejo de árboles de sombra',
      'Aplicar fertilizante según el cronograma',
    ],
  },
};

const Map<String, Map<String, dynamic>> _podTreatmentsEs = {
  'carmenta': {
    'severity': 'moderada',
    'recommendations': [
      'Retirar y destruir rápidamente las mazorcas infestadas',
      'Aplicar insecticidas aprobados (ej. cipermetrina) en picos de vuelo',
      'Cosechar temprano para reducir la acumulación de barrenadores',
      'Usar trampas de feromonas para monitorear la actividad de adultos',
    ],
  },
  'moniliasis': {
    'severity': 'grave',
    'recommendations': [
      'Retirar todas las mazorcas infectadas y enterrarlas o quemarlas inmediatamente',
      'Aplicar fungicidas a base de cobre cada 2–3 semanas en época de lluvias',
      'Podar para mejorar la circulación de aire y reducir la humedad',
      'Cosechar todas las mazorcas maduras y casi maduras para limitar la propagación',
    ],
  },
  'phytophthora': {
    'severity': 'grave',
    'recommendations': [
      'Retirar las mazorcas infectadas inmediatamente y destruirlas lejos de la finca',
      'Aplicar Ridomil o fungicida a base de cobre cada 2 semanas',
      'Limpiar la hojarasca del suelo para reducir el inóculo por salpicadura',
      'Usar materiales de siembra resistentes cuando estén disponibles',
    ],
  },
  'witches_broom': {
    'severity': 'grave',
    'recommendations': [
      'Retirar y quemar todas las escobas y mazorcas enfermas rápidamente',
      'Aplicar fungicida de oxicloruro de cobre después de la poda',
      'Replantar con variedades resistentes cuando sea posible',
      'Reportar brotes graves al extensionista local de COCOBOD',
    ],
  },
  'healthy': {
    'severity': 'ninguna',
    'recommendations': [
      'Continuar el mantenimiento regular y el monitoreo',
      'Cosechar las mazorcas en el punto óptimo de madurez',
      'Mantener el manejo de árboles de sombra para la salud del dosel',
    ],
  },
};

// ── Twi ───────────────────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> _leafTreatmentsTw = {
  'anthracnose': {
    'severity': 'kakra',
    'recommendations': [
      'Yi koko aba a yare aka no na sɛe no ntɛm ara',
      'Fa kɔpa aduro (copper fungicide) gu so',
      'Twitwa nnua no so na mframa nkɔ mu yie',
      'Twa koko aba a abere no ntɛm na yare no ankɔ baabiara',
    ],
  },
  'cssvd': {
    'severity': 'kɛse',
    'recommendations': [
      'Tu nnua a yare aka no ne nnua a ɛbɛn hɔ no nyinaa',
      'Bɔ amanneɛ kyerɛ COCOBOD nkɔso ɔsomfo a ɔwɔ wo mpɔtam',
      'Dua koko aba foforɔ a ɛtumi gyina CSSVD ano',
      'Fa aduro a wɔapene so di mealybug (mmoa a ɛde yare no ba) ho dwuma',
    ],
  },
  'healthy': {
    'severity': 'hwee',
    'recommendations': [
      'Kɔ so hwɛ wo afuo no so daa',
      'Hwɛ nwunu nnua no so yie',
      'Fa nnoboa gu sɛnea ɛsɛ',
    ],
  },
};

const Map<String, Map<String, dynamic>> _podTreatmentsTw = {
  'carmenta': {
    'severity': 'kakra',
    'recommendations': [
      'Yi koko aba a sonsono aka no na sɛe no ntɛm',
      'Fa aduro a wɔapene so (sɛ cypermethrin) di sonsono no ho dwuma',
      'Twa koko no ntɛm na sonsono no annyɛ bebree',
      'Fa pheromone afidie hwɛ sonsono mpɔnkɔsɛm',
    ],
  },
  'moniliasis': {
    'severity': 'kɛse',
    'recommendations': [
      'Yi koko aba a yare aka no nyinaa na sie anaasɛ hyew wɔn ntɛm ara',
      'Fa kɔpa aduro (copper fungicide) gu so daa nnawɔtwe 2-3 biara wɔ osutɔ bere mu',
      'Twitwa nnua no so na mframa nkɔ mu yie',
      'Twa koko aba a abere ne nea ɛbɛn abere nyinaa na yare no ankɔ baabiara',
    ],
  },
  'phytophthora': {
    'severity': 'kɛse',
    'recommendations': [
      'Yi koko aba a yare aka no ntɛm na kɔsɛe no wɔ baabi a ɛkyɛ wɔ afuo no ho',
      'Fa Ridomil anaasɛ kɔpa aduro gu so nnawɔtwe 2 biara',
      'Popa nwura ne nnua ahaban a agu fam no na yare no antew',
      'Dua koko aba a ɛtumi gyina yare no ano sɛ ebinom wɔ hɔ a',
    ],
  },
  'witches_broom': {
    'severity': 'kɛse',
    'recommendations': [
      'Yi nsamanba prae ne koko aba a yare aka no nyinaa na hyew wɔn ntɛm',
      'Fa copper oxychloride aduro gu so twitwa no akyi',
      'Dua koko aba foforɔ a ɛtumi gyina yare no ano sɛ ebetumi a',
      'Bɔ amanneɛ kyerɛ COCOBOD nkɔso ɔsomfo sɛ yare no adɔɔso',
    ],
  },
  'healthy': {
    'severity': 'hwee',
    'recommendations': [
      'Kɔ so hwɛ wo afuo no so daa',
      'Twa koko aba no bere a ɛsɛ',
      'Hwɛ nwunu nnua no so yie ma nnua no nyinaa nkɔ yie',
    ],
  },
};

// ── Public helpers ────────────────────────────────────────────────────────────

/// Get leaf treatment info for [diagnosis] in the given [language].
/// Returns English as fallback.
Map<String, dynamic>? getLeafTreatment(String diagnosis, AppLanguage language) {
  final base = leafTreatments[diagnosis];
  if (base == null) return null;
  if (language == AppLanguage.english) return base;

  final translated = switch (language) {
    AppLanguage.french => _leafTreatmentsFr[diagnosis],
    AppLanguage.spanish => _leafTreatmentsEs[diagnosis],
    AppLanguage.twi => _leafTreatmentsTw[diagnosis],
    AppLanguage.english => null,
  };

  if (translated == null) return base;
  // Merge: use translated severity/recommendations, keep structure from base
  return {
    ...base,
    'severity': translated['severity'] ?? base['severity'],
    'recommendations': translated['recommendations'] ?? base['recommendations'],
  };
}

/// Get pod treatment info for [diagnosis] in the given [language].
/// Returns English as fallback.
Map<String, dynamic>? getPodTreatment(String diagnosis, AppLanguage language) {
  final base = podTreatments[diagnosis];
  if (base == null) return null;
  if (language == AppLanguage.english) return base;

  final translated = switch (language) {
    AppLanguage.french => _podTreatmentsFr[diagnosis],
    AppLanguage.spanish => _podTreatmentsEs[diagnosis],
    AppLanguage.twi => _podTreatmentsTw[diagnosis],
    AppLanguage.english => null,
  };

  if (translated == null) return base;
  return {
    ...base,
    'severity': translated['severity'] ?? base['severity'],
    'recommendations': translated['recommendations'] ?? base['recommendations'],
  };
}
