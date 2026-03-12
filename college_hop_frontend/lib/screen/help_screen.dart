import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {

  TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> faqs = [
    {
      "q": "How does College Hop work?",
      "a": "College Hop connects students attending the same events so they can travel and network together."
    },
    {
      "q": "How do I verify my student status?",
      "a": "Upload your student ID in the verification section of your profile."
    },
    {
      "q": "Is College Hop free to use?",
      "a": "Yes, the core features of College Hop are completely free."
    },
    {
      "q": "How do I join a travel group?",
      "a": "Select an event and join an available travel group from the event page."
    },
    {
      "q": "Can I create my own event?",
      "a": "Yes, you can submit a new event from the My Events screen."
    },
    {
      "q": "How does the matching system work?",
      "a": "Matches are based on shared interests, location, and events you plan to attend."
    },
  ];

  List<Map<String, String>> filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    filteredFaqs = faqs;
  }

  void searchFaq(String query) {
    final results = faqs.where((faq) {
      final question = faq["q"]!.toLowerCase();
      final answer = faq["a"]!.toLowerCase();
      final input = query.toLowerCase();

      return question.contains(input) || answer.contains(input);
    }).toList();

    setState(() {
      filteredFaqs = results;
    });
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// HEADER
            Row(
              children: [

                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      "Help Center",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 16),

            /// SEARCH BAR
            TextField(
              controller: searchController,
              onChanged: searchFaq,
              decoration: InputDecoration(
                hintText: "Search for help...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// CATEGORY TITLE
            Text(
              "Browse by Category",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _categoryTile(theme, "Getting Started", "3 articles"),
            _categoryTile(theme, "Events & Matching", "12 articles"),
            _categoryTile(theme, "Travel Groups", "7 articles"),
            _categoryTile(theme, "Account & Security", "5 articles"),
            _categoryTile(theme, "Verification", "4 articles"),

            const SizedBox(height: 24),

            /// FAQ TITLE
            Text(
              "Frequently Asked Questions",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text("No results found"),
                ),
              )
            else
              ...filteredFaqs.map((faq) => _faqTile(theme, faq)).toList(),

            const SizedBox(height: 24),

            /// SUPPORT CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [

                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 40,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Still need help?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Our support team is here to assist you",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Contact Support"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// CATEGORY TILE
  Widget _categoryTile(ThemeData theme, String title, String subtitle) {

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(.15),
        ),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  /// FAQ TILE
  Widget _faqTile(ThemeData theme, Map<String, String> faq) {

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(.15),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faq["q"]!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(faq["a"]!),
          )
        ],
      ),
    );
  }
}