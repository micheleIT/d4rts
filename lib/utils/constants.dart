enum CheckoutMode { straightOut, doubleOut, tripleOut, masterOut }

const List<int> startingScoreOptions = [301, 501, 701];
const List<int> legsToWinOptions = [1, 2, 3, 5, 7];
const List<int> handicapOptions = [0, 50, 100, 150, 200];

String checkoutModeName(CheckoutMode mode) {
  switch (mode) {
    case CheckoutMode.straightOut:
      return 'Straight Out';
    case CheckoutMode.doubleOut:
      return 'Double Out';
    case CheckoutMode.tripleOut:
      return 'Triple Out';
    case CheckoutMode.masterOut:
      return 'Master Out';
  }
}
