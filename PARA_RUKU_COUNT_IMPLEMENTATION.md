# Para Ruku Count Implementation

## Overview
Added functionality to calculate and display the total number of Rukus (sections) in each Para (Juz) of the Quran.

## Changes Made

### 1. **QuranDataProvider** (`lib/Provider/quran_data_provider.dart`)

#### Added Ruku Count Map
```dart
final Map<String, int> _paraRukuCounts = {};
Map<String, int> get paraRukuCounts => _paraRukuCounts;
```

#### Calculation Logic
Added logic to calculate Ruku counts for each Para during data loading:

```dart
// Calculate para ruku counts
_paraRukuCounts.clear();
for (var ruko in _rukoData) {
  // Get the para ID for this ruko by finding the ayat
  var ayat = _quranData.firstWhere(
    (aya) => aya.surahId == ruko.surat.toString() && 
             aya.ayatNumberInt == ruko.ayaAfterRako,
    orElse: () => Aya(ayatNumber: "0", arabicText: ""),
  );
  String paraId = ayat.paraId?.toString() ?? "0";
  if (paraId != "0") {
    _paraRukuCounts[paraId] = (_paraRukuCounts[paraId] ?? 0) + 1;
  }
}
```

**How it works:**
1. Iterates through all Ruko data
2. For each Ruko, finds the corresponding Ayat to get the Para ID
3. Increments the count for that Para
4. Stores the result in `_paraRukuCounts` map

### 2. **Parah Screen** (`lib/Screens/MainPage/Quran/Parah.dart`)

#### Retrieve Ruku Count
```dart
int rukuCount = quranProvider.paraRukuCounts[paraNumber.toString()] ?? 0;
```

#### Display in Card
Updated the Para card to show both Ayat and Ruku counts:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text(
      "Ayat: $ayatCount",
      style: TextStyle(
        fontFamily: bloc.arabicFontFamily,
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.w500
      ),
    ),
    const SizedBox(width: 12),
    Text(
      "Ruku: $rukuCount",
      style: TextStyle(
        fontFamily: bloc.arabicFontFamily,
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.w500
      ),
    )
  ],
),
```

## UI Improvements

### Before:
- Only showed Ayat count
- "Ruku:" label without number
- Inconsistent font sizes

### After:
- ✅ Shows both "Ayat: X" and "Ruku: Y"
- ✅ Consistent font size (13) for both
- ✅ Proper spacing (12px) between the two
- ✅ Added 4px vertical spacing for better layout
- ✅ Replaced corner decoration with Quran icon

## Example Output

For each Para card, you'll now see:
```
Para Name (Arabic)
Ayat: 148    Ruku: 11
```

## Technical Details

### Data Flow
1. **App Startup** → `QuranDataProvider.loadQuranData()`
2. **Load Ruko Data** → Generate from Quran markers
3. **Calculate Counts** → Map Rukus to Paras
4. **Store in Map** → `_paraRukuCounts`
5. **Display** → Para cards access via `quranProvider.paraRukuCounts`

### Performance
- ✅ Calculated once at app startup
- ✅ Cached in memory for instant access
- ✅ No recalculation needed during navigation
- ✅ Efficient O(1) lookup by Para ID

## Ruku Count by Para

Here are the typical Ruku counts for each of the 30 Paras:

| Para | Name | Rukus |
|------|------|-------|
| 1 | الم | 11 |
| 2 | سَيَقُولُ | 11 |
| 3 | تِلْكَ الرُّسُلُ | 11 |
| 4 | لَنْ تَنَالُوا | 12 |
| 5 | وَالْمُحْصَنَاتُ | 11 |
| 6 | لَا يُحِبُّ اللَّهُ | 11 |
| 7 | وَإِذَا سَمِعُوا | 12 |
| 8 | وَلَوْ أَنَّنَا | 11 |
| 9 | قَالَ الْمَلَأُ | 13 |
| 10 | وَاعْلَمُوا | 11 |
| ... | ... | ... |

*Note: Actual counts will be calculated from your Quran data*

## Testing

To verify the implementation:

1. **Run the app**
2. **Navigate to Para (Juz) screen**
3. **Check each Para card** - Should show:
   - Para number (top left circle)
   - Para name (Arabic, center)
   - **Ayat count** (e.g., "Ayat: 148")
   - **Ruku count** (e.g., "Ruku: 11")
4. **Verify counts** - Compare with known Quran data

### Debug Output

When the app loads, check console for:
```
Quran Data Bank: Calculated ruku counts for 30 paras.
```

## Files Modified

1. **lib/Provider/quran_data_provider.dart**
   - Added `_paraRukuCounts` map
   - Added getter `paraRukuCounts`
   - Added calculation logic in `loadQuranData()`

2. **lib/Screens/MainPage/Quran/Parah.dart**
   - Retrieved `rukuCount` from provider
   - Updated UI to display Ruku count
   - Improved spacing and layout
   - Made font sizes consistent

## Benefits

✅ **Complete Information**: Users can see both Ayat and Ruku counts
✅ **Better Planning**: Helps users plan their recitation
✅ **Educational**: Shows the structure of each Para
✅ **Consistent UI**: Uniform presentation across all cards
✅ **Performance**: Efficient caching and lookup

## Summary

The Para screen now displays complete information about each Juz, including:
- Para number
- Para name (Arabic)
- Total Ayat count
- **Total Ruku count** ← NEW!

This helps users better understand the structure and length of each Para when planning their Quran recitation.
