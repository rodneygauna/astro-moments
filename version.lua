-- Version module
-- Tracks game version and changelog history
--
-- HOW TO USE:
-- 1. When releasing a new version, update Version.current and Version.buildDate
-- 2. Add a new changelog entry at the TOP of the Version.changelog array
-- 3. Maintain the structure for each entry:
--    - version: string matching Version.current (use semantic versioning: MAJOR.MINOR.PATCH)
--    - date: string in format "Month DD, YYYY"
--    - type: "major", "minor", or "patch" (currently for documentation only)
--    - highlights: array of 1-3 key features/changes (shown as bullet points)
--    - changes: table with four arrays:
--      * added: new features or content
--      * fixed: bug fixes
--      * changed: modifications to existing features
--      * upcoming: (optional) features in development or planned for future updates
-- 4. Keep entries user-friendly (not too technical)
-- 5. Save and the changelog will automatically appear in-game via the version badge
--
-- EXAMPLE:
-- {
--     version = "0.4.0",
--     date = "February 1, 2025",
--     type = "minor",
--     highlights = {"New asteroid types", "Sound effects system"},
--     changes = {
--         added = {"Ruby and diamond asteroids", "Background music and SFX"},
--         fixed = {"Rare crash in sector transition"},
--         changed = {"Improved UI responsiveness"},
--         upcoming = {"Boss fight mechanics", "Achievement system"}
--     }
-- }
local Version = {}

Version.current = "1.0.2"
Version.buildDate = "December 28, 2025"

Version.changelog = {{
    version = "1.0.2",
    date = "January 2, 2026",
    type = "patch",
    highlights = {"Universal .love file for all platforms"},
    changes = {
        added = {"Packaged .love file for easy distribution across Windows, macOS, and Linux"},
        fixed = {},
        changed = {},
        upcoming = {}
    }
}, {
    version = "1.0.1",
    date = "December 28, 2025",
    type = "patch",
    highlights = {"Enhanced time warning visibility"},
    changes = {
        added = {"Red flashing effect for time remaining when 10 seconds or less in mining screen"},
        fixed = {},
        changed = {},
        upcoming = {}
    }
}, {
    version = "1.0.0",
    date = "December 27, 2025",
    type = "major",
    highlights = {"Initial release for Codedex Winter 2025 Game Jam", "Complete gameplay loop with 10 sectors",
                  "Full progression and upgrade systems"},
    changes = {
        added = {"Mining gameplay with physics-based spaceship controls",
                 "10 unique sectors with progressive difficulty",
                 "Environmental obstacles: solar flares, cosmic dust, space debris, meteors, and black hole boss",
                 "Buff selection system with rarity tiers", "Permanent upgrade system for spaceship capabilities",
                 "Complete UI with sound effects and music", "Save/load system with persistent progress",
                 "Settings menu with audio and video controls"},
        fixed = {},
        changed = {},
        upcoming = {"New buff varieties", "More spaceship customization options"}
    }
}}

-- Get the most recent changelog entries
function Version.getLatestChanges(count)
    count = count or 3
    local latest = {}
    for i = 1, math.min(count, #Version.changelog) do
        table.insert(latest, Version.changelog[i])
    end
    return latest
end

-- Get changelog for a specific version
function Version.getChangelogByVersion(versionString)
    for _, entry in ipairs(Version.changelog) do
        if entry.version == versionString then
            return entry
        end
    end
    return nil
end

-- Get all changelogs
function Version.getAllChanges()
    return Version.changelog
end

return Version
