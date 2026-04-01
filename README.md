# NewOrderAlert

A World of Warcraft addon that notifies crafters when they receive new Personal Crafting Orders with customizable sound and visual alerts.

## Features

- **Sound Notifications** - Choose from 12 curated in-game sounds
- **Visual Notifications** - Customizable on-screen text with fade animations
- **Order Type Detection** - Detects Personal Crafting Order system messages
- **Multi-Account Friendly** - Different sounds per character help identify which account received an order
- **Background Sound** - Play notifications even when WoW is alt-tabbed
- **Smart Suppression** - Optionally disable notifications during combat or in instances/raids
- **Throttle Protection** - Maximum one notification per 3 seconds to prevent spam
- **Full Customization** - Adjust text position, scale, color, duration, and messages

## Installation

1. Download the addon
2. Extract the `NewOrderAlert` folder to your WoW addons directory:
   - Default path: `World of Warcraft\_retail_\Interface\AddOns\`
3. Restart WoW or type `/reload` if already in-game
4. You should see a confirmation message: "NewOrderAlert v1.0.0 loaded"

## Usage

### Opening the Configuration Panel

Type one of these commands in chat:
- `/noa` - Opens the settings panel
- `/neworderalert` - Alternative command (same as above)

Or navigate to: **ESC > Interface > AddOns > NewOrderAlert**

### Testing Notifications

Before waiting for a real order, test your settings:

- `/noa test` - Test with order message

You can also use the **Test Notification** button in the settings panel.

## Configuration Options

### Sound Settings

- **Enable Sound Notifications** - Master toggle for all sound alerts
- **Sound** - Choose from 12 distinct notification sounds:
  - Raid Warning
  - Ready Check
  - Auction Window
  - Gold Coins
  - Quest Complete
  - Level Up
  - Player Invite
  - Alarm Clock
  - Garrison Toast
  - Map Ping
  - PVP Flag
  - Bonus Roll
- **Channel** - Route sound through Master or SFX audio channel
- **Play sound when WoW is in background** - Notifications play even when alt-tabbed (highly recommended for multi-account setups)

### Display Settings

- **Enable On-Screen Text** - Master toggle for visual notifications
- **Scale** - Adjust text size (0.5x to 2.0x)
- **X Offset** - Move text horizontally (-500 to 500)
- **Y Offset** - Move text vertically (-500 to 500)
- **Duration** - How long text stays visible (2 to 10 seconds)
- **Font Color** - Choose any color via color picker
- **Order Message** - Customize the text shown for Personal orders

### Suppression Settings

- **Suppress notifications in combat** - No alerts while fighting (enabled by default)
- **Suppress notifications in instances/raids** - No alerts in dungeons, raids, scenarios, or PvP (enabled by default)

**Note:** Test notifications (`/noa test`) bypass all suppression rules and throttles.

## Multi-Account Setup Tips

If you run multiple WoW accounts simultaneously:

1. Install the addon on all accounts
2. Choose a **different sound** for each character/account
3. Enable **Play sound when WoW is in background** on all accounts
4. Now when you receive an order, you'll instantly know which account it's on by the sound!

Example setup:
- Account 1 (Main crafter): Raid Warning
- Account 2 (Alt crafter): Gold Coins
- Account 3 (Second crafter): Auction Window

## How It Works

The addon monitors in-game system messages for personal crafting order notifications:

- **Personal Orders**: Detects "You have received a new Personal Crafting Order."

When detected (and not suppressed), it:
1. Plays your selected sound
2. Displays customized on-screen text with a fade animation
3. Waits 3 seconds before allowing the next notification (throttle protection)

## Troubleshooting

### No sound when alt-tabbed

Make sure **"Play sound when WoW is in background"** is enabled in the addon settings. This automatically manages the game's background sound CVar.

### Notifications not appearing

Check that:
- Sound and/or text notifications are enabled (checkboxes)
- You're not in combat or an instance (if suppression is enabled)
- You haven't received a notification in the last 3 seconds (throttle)

### Wrong sound playing

1. Open settings with `/noa`
2. Select the desired sound from the dropdown
3. Click **Test Notification** to preview it

### Settings not saving

Settings are stored account-wide in `SavedVariables/NewOrderAlertDB.lua`.
- Make sure WoW fully closes (don't force quit)
- Check file permissions on your WoW folder

### Text position is off-screen

1. Open settings with `/noa`
2. Reset X Offset and Y Offset to 0
3. Adjust from center position

## Technical Details

- **Version:** 1.0.0
- **Game Version:** WoW Retail (Midnight 12.0+)
- **Localization:** English only
- **Settings Scope:** Account-wide (same settings across all characters)
- **Events Used:** `CHAT_MSG_SYSTEM`, `PLAYER_LOGIN`
- **APIs Used:** `PlaySound`, `UIFrameFadeIn/Out`, `IsInInstance`, `UnitAffectingCombat`

## Support

For bug reports, feature requests, or questions:
- **Email:** golbintoolbox@gmail.com
- **Author:** Nathan

## License

This addon is provided as-is. Feel free to modify for personal use.

## Changelog

### Version 1.0.0 (2026-01-25)
- Initial release
- Sound and visual notifications for Personal orders
- 12 curated sound options
- Full customization of text appearance and position
- Combat and instance suppression
- Background sound support
- Test notification functionality
