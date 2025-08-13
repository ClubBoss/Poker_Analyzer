String? canonicalMixKey(String raw) {
  final key = raw.toLowerCase().replaceAll('_', '').replaceAll('-', '');
  switch (key) {
    case 'monotone':
      return 'monotone';
    case 'twotone':
    case '2tone':
      return 'twoTone';
    case 'rainbow':
      return 'rainbow';
    case 'paired':
      return 'paired';
    case 'acehigh':
      return 'aceHigh';
    case 'lowconnected':
      return 'lowConnected';
    case 'broadway':
    case 'broadwayheavy':
      return 'broadwayHeavy';
    default:
      return null;
  }
}
