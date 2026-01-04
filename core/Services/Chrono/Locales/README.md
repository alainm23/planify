# 🌍 Multi-language Support for Planify

This directory contains multi-language support for Planify's date parsing system.

## 📁 Structure

```
Locales/
├── en/                 # English
├── es/                 # Spanish  
├── template/           # Template files for new languages
├── create_language.sh  # Script to create new languages
├── TEMPLATE.md         # Detailed guide
└── README.md          # This file
```

## 🚀 Adding a New Language

1. Copy the `template/` folder to `[language_code]/`
2. Rename files replacing `TEMPLATE` with your code
3. Edit each file with corresponding translations
4. Register the parser in `Chrono.vala`

## 📝 Files per Language

Each language must implement these parsers:

| File | Purpose | Examples |
|------|---------|----------|
| `Constants.vala` | Months and time units | "january", "week", "year" |
| `CasualDateParser.vala` | Casual dates | "today", "tomorrow", "yesterday" |
| `RelativeDateFormatParser.vala` | Relative dates | "next week", "last month" |
| `CasualTimeParser.vala` | Casual times | "in the morning", "at night" |
| `MonthNameParser.vala` | Month names | "January 15", "March 2024" |
| `TimeExpressionParser.vala` | Time expressions | "at 3pm", "14:30" |
| `DateTimeComboParser.vala` | Combinations | "tomorrow at 9am" |
| `[Language]Parser.vala` | Main parser | Coordinates all parsers |

## 🎯 Common Patterns by Language

### Spanish
- **Casual dates**: hoy, mañana, ayer, pasado mañana
- **Relative dates**: próxima semana, mes pasado, este año
- **Times**: por la mañana, en la tarde, por la noche

### English  
- **Casual dates**: today, tomorrow, yesterday
- **Relative dates**: next week, last month, this year
- **Times**: in the morning, in the afternoon, at night

### French (example)
- **Casual dates**: aujourd'hui, demain, hier
- **Relative dates**: la semaine prochaine, le mois dernier
- **Times**: le matin, l'après-midi, le soir

## 🔧 Implementation Tips

### 1. Regular Expressions
- Use `RegexCompileFlags.CASELESS` to ignore case
- Include variations with and without accents
- Consider plural and singular forms

### 2. Constants
- Add full names and abbreviations for months
- Include all variations of time units
- Consider common synonyms

### 3. Testing
- Test with phrases users would actually write
- Include edge cases like accents, capitals, extra spaces
- Verify no conflicts between parsers

## ✅ Checklist

Before submitting your implementation:

- [ ] All files created and compiling
- [ ] Constants fully translated  
- [ ] Regex patterns working correctly
- [ ] Parser registered in `Chrono.vala`
- [ ] Basic tests passing
- [ ] No conflicts with other languages

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a branch: `git checkout -b add-[language]-support`
3. **Implement** your language following this guide
4. **Test** your implementation
5. **Submit** a pull request

## 📚 Useful Resources

- [ISO Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [Vala Regex Documentation](https://valadoc.org/glib-2.0/GLib.Regex.html)
- [Complete guide in TEMPLATE.md](TEMPLATE.md)

## 🌟 Supported Languages

- ✅ **English** (en) - Complete
- ✅ **Spanish** (es) - Complete
- 🚧 **Your language here** - Contribute!

Help us make Planify accessible to more people! 🚀