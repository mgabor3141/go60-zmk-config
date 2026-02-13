# === mgabor's layout ===

I designed this layout - and decided to learn this keyboard - with a few goals in mind.

In order of priority:
  1. Comfortable symbol layout for programming
  2. Reduce needing to move right hand from mouse when not typing (eg. only to press enter)
  3. No significant departure from row staggered: switching to laptop keyboard should be effortless (when necessary)
  4. Standardize hotkey muscle memory across MacOS and Linux
  5. Eliminate needing to switch keyboard layouts to type non-English characters
    
I'm happy to say I think I managed to achieve most of these goals as of v4 of this layout.

A few notes on some of the key decisions I made, and how the goals above affected them.

## No home row modifiers

Home row mods are great for mostly keyboard workflows, where you can always press modifiers with the opposite hand to the key being modified. For workflows with significant mouse usage, HRMs don't make sense IMO.

## Ctrl and Cmd

I will be using Linux naming throughout the rest of this text. When I write "Ctrl" I mean the "secondary" modifier: Ctrl on Linux, Command on Mac.

While making the two equivalent is not quite as simple as swapping them based on the OS, I don't want to go into too much detail on this topic here. You can check my dotfiles repo for more information here:

https://github.com/mgabor3141/dots/blob/main/.docs/keyboard-remapping.md

## Left hand can hotkey (almost) everything

With the placement of Ctrl and Shift, the most common hotkeys can all be typed with just the left hand. Alt is also on the left side, even though it is not used as frequently.

This is complements the Nav layer, which is activated from a thumb key. All this makes the left keyboard half a very powerful hotkey system.

## The vim-shaped elephant in the room

Vim can do all this and more. This layout does have the advantage that these keybinds work in any appliation, but in truth it's just a different philosophy.

## Window management

The window manager button (Super on Linux, Ctrl on Mac) is also positioned in a way so that it can take maximum advantage of the left half of the keyboard. I use WM+ESDF for directional window switching (workspaces up/down, scrolling windows left/right). When adding the very conveniently placed pinky Shift to any of the keybinds, the action becomes a window move instead of a focus.

The remaining buttons are a mix between resizing, floating toggle, and direct workspace activation. I use Niri and Aerospace for the workspaces, see their respective configs for details:

https://github.com/mgabor3141/dots/tree/main/dot_config/aerospace
https://github.com/mgabor3141/dots/blob/main/dot_config/niri/config.kdl

## More goodies

- The Nav layer is so left-hand focused, the right half can fit an entire numpad. Why not.
- Symbol layer fits locale-specific keys on the right hand side, no layout switching needed.
- Gaming layer is pretty much stock, but the tap-holds are removed for consistent behavior. Alpha layer remains unmodified, which helps when needing to switch applications briefly or having a friendly discussion in allchat. WASD games need to be rebound to use ESDF instead.
- Everyone should have a caps word key!
- Semicolon and colon are swapped because I don't program in languages that mandate semi usage.
- Switching to and from the Gaming layer gives visual feedback.
- Mouse 4 and 5 are so useful that I added an additional pair to the out of reach keys on base layer. They get used occasionally. Comboing both is my global mic mute.
