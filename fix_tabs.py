import re

path = r'c:\meraj3i\myapp\lib\screens\results\competition_stats_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace _buildSchoolTab
school_tab_pattern = r'''(Widget _buildSchoolTab\(\{.*?return )Column\(\s*children: \[\s*// ── رسم بياني شريطي: أفضل 10 مدارس ──────────────────────────────\s*if \(top10\.length >= 2\)\s*Padding\('''
school_tab_repl = r'''\1ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(scrollbars: false),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── رسم بياني شريطي: أفضل 10 مدارس ──────────────────────────────
          if (top10.length >= 2)
            SliverToBoxAdapter(
              child: Padding('''
text = re.sub(school_tab_pattern, school_tab_repl, text, flags=re.DOTALL)

school_search_pattern = r'''(barGroups: List\.generate\(top10\.length, \(i\) \{.*?\n\s*\}\),\s*\),\s*\),\s*\),\s*\],\s*\),\s*\),\s*\),)\s*// شريط البحث بين المدارس\s*Padding\('''
school_search_repl = r'''\1
          // شريط البحث بين المدارس
          SliverToBoxAdapter(
            child: Padding('''
text = re.sub(school_search_pattern, school_search_repl, text, flags=re.DOTALL)

school_header_pattern = r'''(contentPadding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 12\),\s*\),\s*\),\s*\),\s*\),)\s*// عنوان وعدّاد المدارس\s*Padding\('''
school_header_repl = r'''\1
          // عنوان وعدّاد المدارس
          SliverToBoxAdapter(
            child: Padding('''
text = re.sub(school_header_pattern, school_header_repl, text, flags=re.DOTALL)

school_list_pattern = r'''(style: GoogleFonts\.tajawal\(fontSize: 11, color: Colors\.grey\[500\]\),\s*\),\s*\],\s*\),\s*\),)\s*// قائمة المدارس\s*Expanded\(\s*child: filtered\.isEmpty\s*\?\s*Center\(\s*child: Text\(\s*'لا توجد مدارس مطابقة للبحث\.',\s*style: GoogleFonts\.tajawal\(color: Colors\.grey\),\s*\),\s*\)\s*:\s*ListView\.builder\(\s*padding: const EdgeInsets\.fromLTRB\(16, 4, 16, 80\),\s*itemCount: filtered\.length,\s*itemBuilder: \(context, index\) \{\s*final school = filtered\[index\];\s*return _buildSchoolCard\(\s*school: school,\s*isDark: isDark,\s*primaryColor: primaryColor,\s*scoreLabel: scoreLabel,\s*\);\s*\},\s*\),\s*\),\s*\],\s*\);\s*\}'''
school_list_repl = r'''\1
          // قائمة المدارس
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'لا توجد مدارس مطابقة للبحث.',
                  style: GoogleFonts.tajawal(color: Colors.grey),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final school = filtered[index];
                    return _buildSchoolCard(
                      school: school,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      scoreLabel: scoreLabel,
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }'''
text = re.sub(school_list_pattern, school_list_repl, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
