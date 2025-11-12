import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const apiKey = 'AIzaSyBXKzJJPcgK0uYNwf9tpdlcJPw26JvVi2Q';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  /// Expanded mood list
  final List<String> moods = [
    // 😊 Positive moods
    "😊 Happy",
    "😇 Grateful",
    "😌 Content",
    "😎 Confident",
    "🥳 Excited",
    "😚 Loved",
    "🤗 Hopeful",
    "🤩 Inspired",
    "😋 Playful",
    "🤠 Cheerful",
    "🧘 Calm",
    "🙂 Neutral",

    // 😢 Negative moods
    "😢 Sad",
    "💔 Heartbroken",
    "😞 Disappointed",
    "😔 Lonely",
    "😩 Overwhelmed",
    "😕 Confused",
    "😟 Anxious",
    "😰 Stressed",
    "😤 Frustrated",
    "😠 Irritated",
    "😡 Angry",
    "😬 Nervous",
    "😳 Embarrassed",
    "😴 Tired",
    "😫 Exhausted",
    "😩 Hopeless",
    "😶 Empty",
    "😑 Bored",
    "🤒 Unwell",
    "🤯 Burned Out",
    "⚠️ Suicidal/Warning",

    // 🤔 Neutral / Reflective
    "🤔 Reflective",
    "😌 Thoughtful",
    "😮 Surprised",
    "😶 Indifferent",
    "😐 Blank",
    "🫤 Uncertain",
    "🤫 Quiet",
    "😅 Awkward",
    "🤨 Skeptical",
    "🤓 Focused",
    "🤭 Amused"
  ];

  /// Keywords to detect suicidal risk
  final List<String> suicidalKeywords = [
    "i want to die",
    "i want to kill myself",
    "i'm going to kill myself",
    "im going to kill myself",
    "i want to end my life",
    "kill myself",
    "end my life",
    "suicide",
    "i'm suicidal",
    "i am suicidal",
    "i can't go on",
    "i cant go on",
    "i don't want to live",
    "i dont want to live",
    "going to jump",
    "going to overdose",
    "thoughts of suicide",
    "thoughts of killing myself",
    "goodbye forever",
    "no reason to live",
    "die"
  ];

  /// Detect if the input text contains suicidal content
  bool detectSuicidalRisk(String text) {
    final lower = text.toLowerCase();
    for (final keyword in suicidalKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  /// Predict mood based on user text
  Future<String> predictMood(String userText) async {
    try {
      // If text is suicidal, return warning immediately
      if (detectSuicidalRisk(userText)) {
        return "⚠️ Suicidal/Warning";
      }

      // Prompt AI to classify mood using predefined options
      final prompt = """
      The user wrote: "$userText"
      Based on this text, pick the closest mood from the following list: ${moods.join(", ")}.
      Reply ONLY with the mood exactly as it appears in the list.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final aiText = response.text?.trim() ?? "";

      // Return AI mood if it matches the predefined list
      if (moods.contains(aiText)) {
        return aiText;
      }

      // Fallback to Neutral if AI response is unexpected
      return "🙂 Neutral";
    } catch (e) {
      return "🙂 Neutral";
    }
  }
}
