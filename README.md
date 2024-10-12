# GB303 - Zerabosk Edition
GB303 wavetable-based TB-303 style synthesizer for the Nintendo Gameboy.

**This project is a revival attempt.** Files are provided as-is without any guarantees.

### Planned Features:
- [x] Independent cursor movement on sequencer screen during playback. 
- [ ] Replace EEPROM with SRAM & update schematics for more reiable saves.
- [ ] Change POTS via MIDI CC messages.
- [ ] LSDJ Slave sync when looping a single pattern (currently forces song mode)
- [ ] Konamicode etch-a-sketch mode. (maybe)
###### Fix known bugs:
- [x] Beat skip when patten changes in song mode.
- [ ] Beat skip when patten changes in song mode on Pattern page. (Screen redraw too slow)
- [x] Nanoloop misses random beats from GB-303 when in Nanoloop Master mode. 
-- Replaced with working Nanoloop slave mode.
- [x] LSDJ Slave sync is late.
- [ ] Full MIDI mode misses notes randomly. Especially bad when playing fast.
- [x] Pattern names get overwitten (randomly? Maybe to do with saves happening on song start?)
- [ ] Pattern page redraw function is slow and causes delays when changing patterns.

![GB303 prototype](img/prot.jpg)

License: (CC BY 4.0) furrtek 2014~2015. http://creativecommons.org

## Screencaps

![Test](img/keyboard.png)
![Test](img/2dpad.png)
![Test](img/assign.png)
![Test](img/tracker.png)
