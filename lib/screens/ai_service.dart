import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // ✅ Use your working AI Studio key here
  static const apiKey = 'AIzaSyBXKzJJPcgK0uYNwf9tpdlcJPw26JvVi2Q';

  // ✅ Use the model name that actually exists in your key’s project
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash', // ✅ updated from gemini-1.5-flash
    apiKey: apiKey,
  );

  Future<String> getAIResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return "No response from Heneuro 🤖";
      }

      return response.text!;
    } catch (e) {
      return "⚠️ AI Error: ${e.toString()}";
    }
  }
}
