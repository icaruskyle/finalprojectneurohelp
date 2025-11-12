import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const apiKey = 'AIzaSyBXKzJJPcgK0uYNwf9tpdlcJPw26JvVi2Q';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  /// Expanded mood list
  final List<String> moods = [
    "😊 Happy", "😇 Grateful", "😌 Content", "😎 Confident", "🥳 Excited",
    "😚 Loved", "🤗 Hopeful", "🤩 Inspired", "😋 Playful", "🤠 Cheerful",
    "🧘 Calm", "🙂 Neutral", "😢 Sad", "💔 Heartbroken", "😞 Disappointed",
    "😔 Lonely", "😩 Overwhelmed", "😕 Confused", "😟 Anxious", "😰 Stressed",
    "😤 Frustrated", "😠 Irritated", "😡 Angry", "😬 Nervous", "😳 Embarrassed",
    "😴 Tired", "😫 Exhausted", "😩 Hopeless", "😶 Empty", "😑 Bored",
    "🤒 Unwell", "🤯 Burned Out", "⚠️ Suicidal/Warning", "🤔 Reflective",
    "😌 Thoughtful", "😮 Surprised", "😶 Indifferent", "😐 Blank", "🫤 Uncertain",
    "🤫 Quiet", "😅 Awkward", "🤨 Skeptical", "🤓 Focused", "🤭 Amused"
  ];

  final List<String> suicidalKeywords = [
    "i want to die", "i want to kill myself", "i'm going to kill myself",
    "im going to kill myself", "i want to end my life", "kill myself",
    "end my life", "suicide", "i'm suicidal", "i am suicidal",
    "i can't go on", "i cant go on", "i don't want to live",
    "i dont want to live", "going to jump", "going to overdose",
    "thoughts of suicide", "thoughts of killing myself", "goodbye forever",
    "no reason to live", "die"
  ];

  /// Detect suicidal content
  bool detectSuicidalRisk(String text) {
    final lower = text.toLowerCase();
    for (final keyword in suicidalKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  /// Predict mood
  Future<String> predictMood(String userText) async {
    try {
      if (detectSuicidalRisk(userText)) {
        return "⚠️ Suicidal/Warning";
      }

      final prompt = """
      The user wrote: "$userText"
      Based on this text, pick the closest mood from the following list: ${moods.join(", ")}.
      Reply ONLY with the mood exactly as it appears in the list.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final aiText = response.text?.trim() ?? "";
      if (moods.contains(aiText)) return aiText;

      return "🙂 Neutral";
    } catch (e) {
      return "🙂 Neutral";
    }
  }

  /// Chatbot conversational reply
  Future<String> getAIResponse(String userText) async {
    try {
      if (detectSuicidalRisk(userText)) {
        return "⚠️ Your message suggests you may be at risk. Please consider reaching out for help immediately.";
      }

      final prompt = """
      You are Henuero, a kind and friendly AI chatbot. Respond to the user conversationally.
      User said: "$userText"
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text?.trim() ?? "Sorry, I didn't understand that.";
    } catch (e) {
      return "⚠️ AI Error: ${e.toString()}";
    }
  }
}
