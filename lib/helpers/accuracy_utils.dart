double calculateAccuracy(int correct, int total) {
  if (total == 0) {
    return 0;
  }
  return correct * 100 / total;
}
