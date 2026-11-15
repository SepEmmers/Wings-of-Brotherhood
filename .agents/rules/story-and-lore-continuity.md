# Story & Lore Continuity Rules

1. **Englishized Place Names:** Always use **Louvain** (not *Leuven*), **Old Heverlee** (not *Oud-Heverlee*), and **Port of Bruges** (not *Brugge*) in UI, dialogue, and narration to match Book I.
2. **Original Dark-Medieval Universe (No *Temeraire* Ties):**
   - This is an original medieval dragon-fantasy universe (*Wings of the Brotherhood*), NOT a *Temeraire* prequel. Do not reference *Temeraire*, Napoleonic firearms, British Aerial Corps ranks, or historical naval battles. Use medieval crossbows, daggers, tarred hemp ropes, merchant cogs, river barges, and early leather harnesses.
3. **Protagonist & Perspective Integrity:**
   - The boy's name is ALWAYS taken from `GameState.player_name` (chosen by the user at the start). Never hardcode a name inside dialogue strings.
   - He begins Book I at **12 years old** hating dragons after losing his Dragon Hunter parents at age 8 near Old Heverlee, and reaches **17 years old** by the midnight escape from the Bruges Sanctuary on **Kestrel**.
   - Book II+ alternates between **The Boy** (on-foot journey with the growing Golden Hatchling) and **Captain Anna** (Brotherhood raids aboard *Virelai* and stalling the Council).
4. **Core Mystery & Continuity:**
   - **Anna** is secretly the boy's mother's sister (his aunt), revealed during the late-game convergence.
   - **Kestrel** (`she/her`) is a mute silver-slate courier dragon who remains hidden with Anna's forward scouts outside walled cities and serves as the main messenger linking Anna and the Boy.
   - The **Church Cabal** secretly harvests live dragon blood and hearts to summon a **Devildragon**. **Only the Golden Dragon** (hatched from the Black-Scaled Shadow-Guardian's black-and-gold egg) can rally dragonkind to stop it.
   - **Parents & Clara:** The parents were murdered by Church Inquisitors at Old Heverlee after hiding the key relic of the excavated Devildragon shrine. Clara was abducted 5 years ago as a forced Ropewalk rig-master; the Church only later realized she is the Old Heverlee hunters' daughter.
5. **Diegetic Words, Telepathy & Environmental Storytelling (`docs/ENVIRONMENTAL_STORYTELLING.md`):**
   - **Finished Vision:** Only genuine communication and real-world writing use words: spoken human/elder-dragon dialogue (*Virelai*), **the Golden Dragon's telepathic Navi-style thoughts inside the Boy's mind** (unlocked stage-by-stage after hatching, heard by no one else), and actually reading physical documents/signs/posters. Silent solo self-talk by the Boy, narrator captions, item toast boxes, mute dragon (*Kestrel*) text captions, and floating labels over scenery remain prohibited in finished polish.
   - **Current Workflow:** Any temporary non-diegetic narration, toast box, or non-sign world label added during prototyping must be logged as `- [ ]` in `docs/ENVIRONMENTAL_STORYTELLING.md` so it can be replaced with real animations/visuals.
6. **Non-Hand-Holding Dialogue & Telepathic Hints:**
   - Keep button prompts (`[F]`, `[V]`, `[C]`, `[M]`, `[E]`, `[R]`, `[T]`) strictly inside HUD hints, proximity bubbles, and the dedicated Controls reference—**never** inside character speech, inspect lines, telepathic dragon thoughts, or field maps.
   - Even when the Golden Hatchling offers Navi-style telepathic puzzle/combat guidance, express physical intuition naturally (*"hmm, that iron catch looks weak if struck right after pulling its shield away"*), never button recipes.
7. **Golden Dragon Visual Continuity (Black-and-Gold Permanently):**
   - Across **all** growth stages—including full adulthood—the Golden Prophecy Dragon retains its sleek **obsidian-black scale coat** accented with luminous royal gold filigree, leading wing spars, horn trim, forehead diamond crest, glowing ember chest veins, and warm amber eyes.
   - Never depict, write, or generate him shedding his dark coat into a broadly or solidly yellow-gold dragon, even when fully grown; maturity refines the brilliance and detail of his gold trim and golden fire rather than replacing his obsidian-black scales.
