import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String source;
  final String publishedAt;
  final String? image;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.image,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        title: json['title'] ?? '',
        description: json['description'] ?? 'Sem descrição disponível.',
        url: json['url'] ?? '',
        source: json['source']?['name'] ?? 'Desconhecido',
        publishedAt: json['publishedAt'] ?? '',
        image: json['image'],
      );
}

class NewsService {
  static const _apiKey = '51d940bb93bc90c02d4eacf25b64abbe';
  static const _baseUrl = 'https://gnews.io/api/v4';

  Future<List<NewsArticle>> getFinanceNews() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      throw Exception('Sem conexão com a internet');
    }

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/search?q=finanças+investimentos+economia&lang=pt&country=br&max=10&apikey=$_apiKey',
      ),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final articles = data['articles'] as List;
      return articles.map((e) => NewsArticle.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar notícias: ${response.statusCode}');
    }
  }
}