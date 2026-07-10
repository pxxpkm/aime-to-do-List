/// AniList GraphQL query strings — centralized, never inline elsewhere.
class AniListQueries {
  static const search = r'''
    query SearchMedia($search: String, $type: MediaType, $perPage: Int) {
      Page(perPage: $perPage) {
        media(search: $search, type: $type) {
          id
          title {
            romaji
            native
            english
          }
          coverImage {
            extraLarge
            large
            medium
          }
          episodes
          chapters
          volumes
          status
          description
          averageScore
        }
      }
    }
  ''';

  static const detail = r'''
    query MediaDetail($id: Int) {
      Media(id: $id) {
        id
        title {
          romaji
          native
          english
        }
        coverImage {
          extraLarge
          large
          medium
        }
        bannerImage
        episodes
        chapters
        volumes
        status
        description
        averageScore
        genres
      }
    }
  ''';
}
