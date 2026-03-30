/// Representa uma resposta paginada da API.
///
/// Contém uma lista de itens [T] para a página atual e o
/// número total de itens disponíveis no servidor.
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final bool hasMore;

  PaginatedResponse({required this.items, required this.totalCount, required this.hasMore});
}
