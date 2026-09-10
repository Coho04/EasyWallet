import 'package:easy_wallet/class/translatable_enum.dart';

/// The kind of service a catalog entry is, as the catalog API names it.
///
/// The API sends a stable, untranslated slug and promises only to add new ones,
/// never to rename an existing one. [value] is the key the app translates
/// under, kept separate from [slug] so the wire format and the translation
/// catalog can be spelled the way each of them wants to be.
enum TemplateCategory with TranslatableEnum {
  streamingVideo(slug: 'streaming_video', value: 'categoryStreamingVideo'),
  streamingMusic(slug: 'streaming_music', value: 'categoryStreamingMusic'),
  streamingAudio(slug: 'streaming_audio', value: 'categoryStreamingAudio'),
  cloudStorage(slug: 'cloud_storage', value: 'categoryCloudStorage'),
  software(slug: 'software', value: 'categorySoftware'),
  gaming(slug: 'gaming', value: 'categoryGaming'),
  news(slug: 'news', value: 'categoryNews'),
  fitness(slug: 'fitness', value: 'categoryFitness'),
  telecom(slug: 'telecom', value: 'categoryTelecom'),
  food(slug: 'food', value: 'categoryFood'),
  other(slug: 'other', value: 'categoryOther');

  const TemplateCategory({
    required this.slug,
    required this.value,
  });

  /// The identifier the API sends.
  final String slug;

  @override
  final String value;

  /// The category for a slug from the API. Unknown slugs become [other]: the
  /// catalog may add categories that this app version has never heard of, and
  /// a new one must not hide the service it belongs to.
  static TemplateCategory findBySlug(String? slug) {
    if (slug == null) {
      return TemplateCategory.other;
    }
    final wanted = slug.trim().toLowerCase();
    for (final category in TemplateCategory.values) {
      if (category.slug == wanted) {
        return category;
      }
    }
    return TemplateCategory.other;
  }
}
