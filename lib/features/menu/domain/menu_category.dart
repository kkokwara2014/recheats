/// Menu browse categories shown on Home.
enum MenuCategory {
  rice('Rice', 'rice'),
  soups('Soups', 'soups'),
  swallow('Swallow', 'swallow'),
  proteins('Proteins', 'proteins'),
  snacks('Snacks', 'snacks'),
  drinks('Drinks', 'drinks');

  const MenuCategory(this.label, this.id);

  final String label;
  final String id;

  static MenuCategory? fromId(String id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}
