import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const apiKey = 'AIzaSyCYDtNOJMiUvVl5gHcu2wJTDgb3ItxLrGM';

  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

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

  bool detectSuicidalRisk(String text) {
    final lower = text.toLowerCase();
    for (final keyword in suicidalKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  Future<String> predictMood(String userText) async {
    try {
      if (detectSuicidalRisk(userText)) return "⚠️ Suicidal/Warning";

      final prompt = """
      The user wrote: "$userText"
      The text may be in any language. Detect the mood based on the text and pick the closest mood from the following list: ${moods.join(", ")}.
      Reply ONLY with the mood exactly as it appears in the list.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final aiText = response.text?.trim() ?? "";
      return moods.contains(aiText) ? aiText : "🙂 Neutral";
    } catch (e) {
      return "🙂 Neutral";
    }
  }

  Future<String> getAIResponse(String conversationContext) async {
    try {
      if (detectSuicidalRisk(conversationContext)) {
        return "⚠️ Your messages suggest you may be at risk. Please consider reaching out for help immediately.";
      }

      final prompt = """
      You are Henuero, a kind and friendly AI chatbot. 
      Engage in a continuous conversation with the user. 
      Respond naturally, considering all previous messages below:

      $conversationContext

      Reply as Henuero, be empathetic, clear, and concise.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text?.trim() ?? "Sorry, I didn't understand that.";
    } catch (e) {
      return "⚠️ AI Error: ${e.toString()}";
    }
  }

  Future<List<String>> getMusicForMood(String mood, String category) async {
    try {
      if (detectSuicidalRisk(mood)) {
        return [
          "https://www.iasp.info/resources/Crisis-Centres/",
          "https://suicidepreventionlifeline.org/"
        ];
      }

      final prompt = """
      Provide a list of 10 YouTube links for $category suitable for someone feeling $mood.
      Only give the links, no descriptions or extra text.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final urls = RegExp(r'(https?://[^\s]+)').allMatches(response.text ?? "")
          .map((m) => m.group(0)!)
          .toList();

      return urls.isNotEmpty ? urls : [];
    } catch (e) {
      return [];
    }
  }
}