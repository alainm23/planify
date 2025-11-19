# Adding New Language Support

This guide will help you add support for a new language in Planify's date parsing system.

## 📁 File Structure

To add a new language, you need to create a folder with the ISO language code (e.g., `fr` for French, `de` for German) inside `core/Services/Chrono/Locales/`.

### Required Files

Each language must have these files:

```
Locales/[language_code]/
├── [CODE]Constants.vala          # Language constants
├── [CODE]CasualDateParser.vala   # Casual date parser
├── [CODE]CasualTimeParser.vala   # Casual time parser  
├── [CODE]MonthNameParser.vala    # Month name parser
├── [CODE]RelativeDateFormatParser.vala # Relative date parser
├── [CODE]TimeExpressionParser.vala     # Time expression parser
├── [CODE]DateTimeComboParser.vala      # Combined parser
└── [Language]Parser.vala         # Main parser
```

## 🚀 Steps to Add a New Language

### 1. Create Language Folder

```bash
mkdir core/Services/Chrono/Locales/[language_code]
```

### 2. Copy Templates

Copy template files and rename them:

```bash
cp core/Services/Chrono/Locales/template/* core/Services/Chrono/Locales/[language_code]/
```

### 3. Customize Files

Edit each file replacing:
- `TEMPLATE` → language code in uppercase (e.g., `FR`, `DE`)
- `Template` → language name (e.g., `French`, `German`)
- Constants and patterns with corresponding translations

### 4. Register New Parser

Add the new parser in `core/Services/Chrono/Chrono.vala`:

```vala
// In constructor, add:
parsers.add (new [Language]Parser ());
```

## 📝 Pattern Examples by Language

### Relative Dates
- **Spanish**: "la próxima semana", "el mes pasado"
- **French**: "la semaine prochaine", "le mois dernier"
- **German**: "nächste Woche", "letzten Monat"

### Casual Dates
- **Spanish**: "hoy", "mañana", "ayer"
- **French**: "aujourd'hui", "demain", "hier"
- **German**: "heute", "morgen", "gestern"

### Times
- **Spanish**: "por la mañana", "en la tarde"
- **French**: "le matin", "l'après-midi"
- **German**: "am Morgen", "am Nachmittag"

## 🔧 Implementation Tips

1. **Use flexible regex patterns** that capture common variations
2. **Include accented and unaccented versions** for better compatibility
3. **Consider plural and singular forms** of all words
4. **Test with real phrases** users would actually write
5. **Document supported patterns** in comments

## ✅ Checklist

- [ ] All files created and renamed
- [ ] Constants translated (months, time units)
- [ ] Regex patterns updated
- [ ] Main parser registered in Chrono.vala
- [ ] Basic tests working
- [ ] Documentation updated

## 🤝 Contributing

Once your implementation is ready:

1. Fork the repository
2. Create a branch for your language: `git checkout -b add-[language]-support`
3. Commit your changes: `git commit -m "Add [language] language support"`
4. Submit a pull request

Thanks for helping make Planify more accessible! 🌍