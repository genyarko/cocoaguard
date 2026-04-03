// Leaf disease treatments (3 classes from EfficientNetB3 leaf model).
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

// Pod disease treatments (5 classes from YOLO + EfficientNet pod pipeline).
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
