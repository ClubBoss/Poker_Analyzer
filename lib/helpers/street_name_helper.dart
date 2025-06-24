const streetNames = ['Preflop', 'Flop', 'Turn', 'River'];

String streetName(int index) {
  return streetNames[index.clamp(0, streetNames.length - 1)];
}
