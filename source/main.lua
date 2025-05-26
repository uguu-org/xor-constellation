--[[ Xor Constellation

XOR a chain of bytes to make 0x0 or 0xf.
--]]

import "CoreLibs/graphics"
import "CoreLibs/ui"
import "data"

----------------------------------------------------------------------
--{{{ Debug functions.

-- Print a message, and return true.  The returning true part allows this
-- function to be called inside assert(), which means this function will
-- be stripped in the release build by strip_lua.pl.
local function debug_log(msg)
	print(string.format("[%f]: %s", playdate.getElapsedTime(), msg))
	return true
end

-- Log an initial message on startup, and another one later when the
-- initialization is done.  This is for measuring startup time.
local random_seed = playdate.getSecondsSinceEpoch()
local title_version <const> = playdate.metadata.name .. " v" .. playdate.metadata.version
assert(debug_log(title_version .. " (debug build), random seed = " .. random_seed))
math.randomseed(random_seed)

-- Draw frame rate in debug builds.
local function debug_frame_rate()
	playdate.drawFPS(24, 220)
	return true
end

-- Increment debug counter.
local function debug_count(v)
	if not debug_counters then
		debug_counters = {}
	end
	if debug_counters[v] then
		debug_counters[v] += 1
	else
		debug_counters[v] = 1
	end
	return true
end

-- Reset debug counters.
local function debug_reset_counts()
	debug_counters = nil
	return true
end

-- Log debug counters.
local function debug_log_counts()
	if debug_counters then
		local t = {}
		for k, v in pairs(debug_counters) do
			table.insert(t, k .. "=" .. v)
		end
		table.sort(t)
		local text = ""
		for i, p in ipairs(t) do
			text = text .. p .. " "
		end
		debug_log(text)
	end
	return true
end

-- Log debug counters periodically.
local function debug_periodic_log()
	if debug_last_log_age then
		debug_last_log_age += 1
		if debug_last_log_age == 150 then
			debug_log_counts()
			debug_last_log_age = 0
		end
	else
		debug_log_counts()
		debug_last_log_age = 0
	end
	return true
end

--}}}

----------------------------------------------------------------------
--{{{ Game data.

-- Constants.
local gfx <const> = playdate.graphics
local abs <const> = math.abs
local floor <const> = math.floor
local max <const> = math.max
local min <const> = math.min
local rand <const> = math.random
local sin <const> = math.sin
local cos <const> = math.cos
local sqrt <const> = math.sqrt

-- Screen dimensions.
local SCREEN_CENTER_X <const> = 200
local SCREEN_CENTER_Y <const> = 120

-- Vertical text position for various button help texts.
local TITLE_HELP_TEXT_POSITION <const> = 210

-- Title animation settings.
-- 0..15 = fade in (characters appear one by one).
-- 16..18 = wait.
-- 19..32 = scroll from y+28 to y+0.
local TITLE_FADE_IN_FRAMES <const> = 16
local TITLE_WAIT_FRAMES <const> = 3
local TITLE_SCROLL_FRAMES <const> = 14
local TITLE_ANIMATION_FRAMES <const> = TITLE_FADE_IN_FRAMES + TITLE_WAIT_FRAMES + TITLE_SCROLL_FRAMES

-- Maximum targets in a chain.  This is used for limiting chains constructed
-- by players, and also maximum recursion depth during grid construction.
--
-- Roughly 24 targets can be partially displayed on screen, so if we start
-- from the center of the screen and perform a random walk, we will reach
-- outside the visible area in at most 24 steps.  Even if we managed to stay
-- with visible screen area in 24 steps, there will be some earlier step along
-- the path that is adjacent to the edge of the screen, so 24 steps very much
-- guarantees that depth-first expansion will definitely reach outside of the
-- visible area.  This means generate_solutions is guaranteed to create valid
-- solutions.  In practice, we will most likely reach the edge much sooner.
-- generate_solutions rarely produce chains that are longer than 16.
--
-- If we want to be absolutely conservative about this (i.e. count even
-- targets near the edges that are barely visible), we will need to go
-- up to about 31.  But since score increases exponentially with respect
-- to chain length, there is a real danger of overflowing signed 32bits
-- if we allow chains that are too long, hence the limit at 24.
local MAX_CHAIN_LENGTH <const> = 24

-- Target spacings.
--
-- Every other column is offset by half of TARGET_Y_SPACING, so the layout
-- resembles a hexagonal grid.  See assert at the beginning of init_target
-- for expected alignments.
local TARGET_X_SPACING <const> = 70
local TARGET_Y_SPACING <const> = 64
assert(TARGET_X_SPACING % 2 == 0)
assert(TARGET_Y_SPACING % 2 == 0)

-- Range of pixels away from screen center for targets to be considered
-- visible.  These need to values that are more than half of screen size
-- plus sprite size, and also be an integer multiple of target spacing.
local DRAW_HALF_WIDTH <const> = 280
local DRAW_EVEN_HALF_HEIGHT <const> = 192
local DRAW_ODD_HALF_HEIGHT <const> = 224
assert(DRAW_HALF_WIDTH % TARGET_X_SPACING == 0)
assert(DRAW_HALF_WIDTH >= SCREEN_CENTER_X + TARGET_X_SPACING // 2)
assert(DRAW_EVEN_HALF_HEIGHT % TARGET_Y_SPACING == 0)
assert(DRAW_EVEN_HALF_HEIGHT >= SCREEN_CENTER_Y + TARGET_Y_SPACING // 2)
assert((DRAW_ODD_HALF_HEIGHT * 2) % TARGET_Y_SPACING == 0)
assert(DRAW_ODD_HALF_HEIGHT >= SCREEN_CENTER_Y + TARGET_Y_SPACING // 2)

-- Hint display modes, used by "hint_mode".
local HINTS_DELAYED <const> = 1
local HINTS_VISIBLE <const> = 2
local HINTS_HIDDEN <const> = 3
local HINT_LABELS <const> = {"delayed", "visible", "hidden"}

-- Target states.
--  unselected = target is not part of the current chain.
--  committed = target has been added to current chain.
--
-- Note that there isn't a "selected" state, because targets that are currently
-- pointed by the cursor retain their "unselected" state, we just draw a circle
-- around them to show that they are selected.
local TARGET_UNSELECTED <const> = 1
local TARGET_COMMITTED <const> = 2

-- Target offsets, indexed by "(next_target_direction + 30) // 60".
local TARGET_OFFSET <const> =
{
	[0] = {0, -TARGET_Y_SPACING},
	[1] = {TARGET_X_SPACING, -TARGET_Y_SPACING // 2},
	[2] = {TARGET_X_SPACING, TARGET_Y_SPACING // 2},
	[3] = {0, TARGET_Y_SPACING},
	[4] = {-TARGET_X_SPACING, TARGET_Y_SPACING // 2},
	[5] = {-TARGET_X_SPACING, -TARGET_Y_SPACING // 2},
	-- Need extra entry around 0 degree due to wraparound.
	[6] = {0, -TARGET_Y_SPACING},
}

-- Sprites.
local LARGE_DIGIT_WIDTH <const> = 20
local LARGE_DIGIT_HEIGHT <const> = 32
local LARGE_DIGIT_HALF_WIDTH <const> = LARGE_DIGIT_WIDTH // 2
local LARGE_DIGIT_HALF_HEIGHT <const> = LARGE_DIGIT_HEIGHT // 2
local SMALL_DIGIT_WIDTH <const> = 8
local SMALL_DIGIT_HEIGHT <const> = 13
local SPRITE_WIDTH <const> = 96
local SPRITE_HEIGHT <const> = 64
local SPRITE_HALF_WIDTH <const> = SPRITE_WIDTH // 2
local SPRITE_HALF_HEIGHT <const> = SPRITE_HEIGHT // 2
local DOTS_WIDTH <const> = 26
local DOTS_HEIGHT <const> = 6
local STAR_SIZE <const> = 1024
local STAR_TILE_SIZE <const> = 32
local STAR_VARIATION_COUNT <const> = 10
local TITLE_TEXT_X <const> = 103
local TITLE_TEXT_Y <const> = 50
local large_digit <const> = gfx.imagetable.new("images/large-digit")
local small_digit <const> = gfx.imagetable.new("images/small-digit")
local sprite <const> = gfx.imagetable.new("images/sprite")
local dots <const> = gfx.imagetable.new("images/dots")
local stars <const> = gfx.imagetable.new("images/stars")
local mode_popups <const> = gfx.imagetable.new("images/modes")
local title_background <const> = gfx.image.new("images/title-background")
local title_char <const> = gfx.imagetable.new("images/title-char")
assert(large_digit)
assert(small_digit)
assert(sprite)
assert(dots)
assert(stars)
assert(mode_popups)
assert(title_background)
assert(title_char)

-- Check that the image table sizes are really what we think they are.
-- We check the loaded sizes against the constants so that the sizes
-- can be inlined at compile time.  Handling the sizes dynamically would
-- be more flexible, but costs an extra variable lookup.
assert(({large_digit[1]:getSize()})[1] == LARGE_DIGIT_WIDTH)
assert(({large_digit[1]:getSize()})[2] == LARGE_DIGIT_HEIGHT)
assert(({small_digit[1]:getSize()})[1] == SMALL_DIGIT_WIDTH)
assert(({small_digit[1]:getSize()})[2] == SMALL_DIGIT_HEIGHT)
assert(({sprite[1]:getSize()})[1] == SPRITE_WIDTH)
assert(({sprite[1]:getSize()})[2] == SPRITE_HEIGHT)
assert(({dots[1]:getSize()})[1] == DOTS_WIDTH)
assert(({dots[1]:getSize()})[2] == DOTS_HEIGHT)
assert(({stars:getSize()})[1] == STAR_VARIATION_COUNT * 2)
assert(({stars:getSize()})[2] == 1)
assert(({stars[1]:getSize()})[1] == STAR_TILE_SIZE)
assert(({stars[1]:getSize()})[2] == STAR_TILE_SIZE)
assert(({mode_popups:getSize()})[1] == 2)
assert(({mode_popups:getSize()})[2] == 1)
assert(({title_char:getSize()})[1] == 1)
assert(({title_char:getSize()})[2] == TITLE_FADE_IN_FRAMES)
assert(({title_background:getSize()})[1] == 400)
assert(({title_background:getSize()})[2] == 240)
assert(STAR_SIZE % STAR_TILE_SIZE == 0)

-- When game is in autoplay mode, perform an action at this period.
-- 1 means perform an action on every frame, 30 means perform one action
-- every second.  Reducing this value allows the human to sort of watch
-- what's happening.
--
-- Turn and advance/undo are treated as separate actions.
--
-- For fastest results in exercising as many actions as possible, set
-- AUTOPLAY_ACTION_PERIOD to 1.  Testing via autoplay tend to be not very
-- useful because the results aren't so reproducible, and this has to do
-- with the random number generator being disturbed by the title screen.
-- It's mostly something that's fun to watch, which is why the period is
-- not set to 1 here.
local AUTOPLAY_ACTION_PERIOD <const> = 4

-- Expected button sequence to enable autoplay.
local AUTOPLAY_BACKDOOR_SEQUENCE <const> =
{
	playdate.kButtonUp,
	playdate.kButtonUp,
	playdate.kButtonDown,
	playdate.kButtonDown,
	playdate.kButtonLeft,
	playdate.kButtonRight,
	playdate.kButtonLeft,
	playdate.kButtonRight,
}
assert(#AUTOPLAY_BACKDOOR_SEQUENCE == 8)
local AUTOPLAY_ENABLED <const> = 9

-- Autoplay modes.
local AUTOPLAY_RANDOM <const> = 1
local AUTOPLAY_RANDOM_AVOID_OBSTACLE <const> = 2
local AUTOPLAY_FOLLOW_HINT_ANY <const> = 3
local AUTOPLAY_FOLLOW_HINT_LONG <const> = 4
local AUTOPLAY_FOLLOW_HINT_ZERO <const> = 5
local AUTOPLAY_FOLLOW_HINT_ONE <const> = 6

-- Sounds.
assert(MAX_NOTE_CHANNELS > 1)
local celesta = table.create(MAX_NOTE_CHANNELS, 0)
celesta[1] = playdate.sound.sampleplayer.new("sounds/celesta")
assert(celesta[1])
for i = 2, MAX_NOTE_CHANNELS do
	celesta[i] = celesta[1]:copy()
end

-- Channels.
local channel = table.create(#celesta, 0)
for i = 1, #celesta do
	channel[i] = playdate.sound.channel.new()
	channel[i]:addSource(celesta[i])
end

-- Tilemap for displaying bits from current chain.
--
-- Need MAX_CHAIN_LENGTH rows for the chain result, +6 for the following:
-- 1. Separator line.
-- 2. XOR result of current chain.
-- 3. Preview of next target pointed by cursor.
-- 4. Separator line
-- 5. XOR result of current chain plus next target.
-- 6. Trailing blank.
local xor_result = gfx.tilemap.new()
xor_result:setSize(2, MAX_CHAIN_LENGTH + 6)
xor_result:setImageTable(dots)

-- Tilemap for displaying current score.
--
-- Need 11 cells:
-- +1 for leading space.
-- +2 for "0x" prefix.
-- +8 for 32bit score.
local score_display = gfx.tilemap.new()
score_display:setSize(11, 1)
score_display:setImageTable(small_digit)

-- Tilemap for displaying high score.
--
-- Need 13 cells:
-- +2 for "HI"
-- +1 for space.
-- +2 for "0x" prefix.
-- +8 for 32bit score.
local high_score_display = gfx.tilemap.new()
high_score_display:setSize(13, 1)
high_score_display:setImageTable(small_digit)

-- Starfield layers.  Initialized in init_starfield.
local starfield = nil

-- Screen buffer for draw_inverted_starfield().
local inverted_starfield = nil

-- Saved state.
local SAVE_STATE_MODE <const> = "m"
local SAVE_STATE_HINT <const> = "h"
local SAVE_STATE_SCORES <const> = "s"
local persistent_state = nil

-- Global clock.
--
-- Each target has a birth_frame timestamp that indicates when it was born,
-- and we decide on its animation state based on its age.  This is so that
-- we only need to update global_frames to animate all targets, instead of
-- having to update individual frame counters at each target.
local global_frames = nil

-- Timestamp of last significant operation, used for determining idleness.
--
-- + In game_loop state, this is updated on advance/undo.
-- + In game_title state, any button press will update this timestamp.
local last_action_timestamp = nil

-- Total amount of "thinking time" in number of frames.
-- Game ends when all the thinking time has been exhausted.
--
-- See update_game_time for how this is incremented.
local thinking_time = nil

-- Do not charge thinking_time if player completes a move within this many
-- frames.
local FAST_THINK_THRESHOLD <const> = 15
assert(FAST_THINK_THRESHOLD < 30)

-- End the game when thinking_time has exceeded this threshold.
local ENDGAME_HARD_LIMIT <const> = 300 * (30 - FAST_THINK_THRESHOLD)

-- Slowly fade to white once thinking_time has exceeded this threshold.
local ENDGAME_LOW_WATERMARK <const> = ENDGAME_HARD_LIMIT * 8 // 10

-- Current score.
local score = nil

-- Score multiplier for newly completed chains.  This is incremented when
-- player completes chains with the same XOR result as the previous chain.
local score_multiplier = nil

-- Number of chains completed.
local completed_chain_count = nil

-- Result from the last completed chain.  This is -1 when player has not
-- completed any chains yet, otherwise it's 0x0/0xf or 0x00/0xff.
local last_completed_xor_result = nil

-- Next target direction [0..359].
local next_target_direction = nil

-- List of {x,y,direction} tuples that have been committed to current chain.
local current_chain = nil

-- Candidate solution paths, a list of {x,y} tuples.  This is used for
-- hint display.
--
-- The initial motivation for hint display was to debug grid generation,
-- but since we got it, we have used it to implement autoplay (by following
-- hints automatically).  And since we got autoplay, we have used that to
-- implement attract mode.  So now we have a game where we can pretty much
-- just sit back watch without actually playing the game at all.
local solution_path_0 = nil
local solution_path_f = nil

-- Target data, a 2D table indexed by [x][y], with these values:
-- {
--    value = operand value [0x00..0xff].
--    motion = oscillating motion type [1..DRIFT_OFFSET_COUNT].
--    motion_phase = motion phase shift [1..DRIFT_FRAME_COUNT].
--    sx, sy = cached screen coordinate, populated by init_target().
--    variation = if value is 0, this is the sprite variation [3..32].
--    selected = selection state [UNSELECTED, SELECTED, COMMITTED].
--    birth_frame = frame index for when this target was initialized.
--    birth_variation = sprite set for birth animation [0..7].
--    maze_generation = see generate_solutions().
-- }
--
-- Table is lazily initialized as we expand the camera view.  Overflow
-- in the table indices doesn't happen because player can't travel that far:
--
--   2**31 / (96 pixels per frame * 30 frames per second) = ~8 days
--
-- Each game ends in a few minutes, and we will probably run out of memory
-- first anyway.
--
-- Now, if the player wants to exhaust all available memory, they can enable
-- autoplay mode and wait, but it will take quite a while since autoplay
-- tend to not drift very far away from origin.  This is because we generated
-- the grid by branching out in all directions at random, so on average the
-- solutions will be near the origin.  Of course the player can expand in
-- one direction manually, but it takes quite a while to do that too and it's
-- just not a particularly fun thing to do.  So rather than implementing a
-- a garbage collector to clean up distant targets, my bet is that player
-- will run out of patience before we run out of memory.
local target = nil

-- Coordinate of current cursor position.
local cursor_x = nil
local cursor_y = nil

-- Coordinate of viewport center.
local camera_x = nil
local camera_y = nil

-- Camera velocity and acceleration direction (degrees) for title screen.
local title_camera_vx = nil
local title_camera_vy = nil
local title_camera_a = nil

-- Array of visibility bits for title screen characters.
local title_char_visible = nil

-- Syntactic sugar for frequently accessed save state entries.
local game_mode = nil
local hint_mode = nil

-- Bit pattern with all bits set, either 0xf or 0xff depending on game mode.
local all_ones = nil

-- Current note group [1..#NOTE_GROUPS].
local note_group_index = nil

-- Last note within the note group that was played [0..MAX_NOTE_CHANNELS].
-- Zero means a note has not been played yet.
local last_note_index = nil

-- Debug backdoor.  See handle_autoplay.
local autoplay_level = nil
local autoplay_mode = nil

-- Forward declarations of game states.
local game_title, game_edit_score, game_demo
local game_loop, game_over, game_over_high_score

--}}}

----------------------------------------------------------------------
--{{{ Game functions.

-- Get game_state name for debug logging.
local function state_name(state)
	assert(type(state) == "function")
	if state == game_title then return "game_title" end
	if state == game_edit_score then return "game_edit_score" end
	if state == game_demo then return "game_demo" end
	if state == game_loop then return "game_loop" end
	if state == game_over then return "game_over" end
	if state == game_over_high_score then return "game_over_high_score" end
	return "UNKNOWN"
end

-- State update function.
local function set_next_game_state(state)
	assert(type(state) == "function")
	assert(debug_log("@" .. (global_frames or "?") .. ": " .. state_name(playdate.update) .. " -> " .. state_name(state)))
	playdate.update = state
end

-- Reset all game states, but keep game_mode and hint_mode unchanged.
local function reset(return_to_title)
	assert(type(return_to_title) == "boolean")

	if return_to_title then
		set_next_game_state(game_title)
	end

	target = {}
	global_frames = 0

	last_action_timestamp = 0
	next_target_direction = 0

	all_ones = (game_mode <= 4) and 0xf or 0xff
	thinking_time = 0
	score = 0
	score_multiplier = 1
	completed_chain_count = 0
	last_completed_xor_result = -1
	for i = 1, 11 do
		score_display:setTileAtPosition(i, 1, -1)
	end
	for i = 1, MAX_CHAIN_LENGTH + 6 do
		xor_result:setTileAtPosition(1, i, -1)
		xor_result:setTileAtPosition(2, i, -1)
	end

	current_chain = nil
	solution_path_0 = nil
	solution_path_f = nil

	note_group_index = 1
	last_note_index = 0

	cursor_x = 0
	cursor_y = 0
	camera_x = 0
	camera_y = 0
	title_camera_vx = 0
	title_camera_vy = 0
	title_camera_a = 0
	title_char_visible = table.create(TITLE_FADE_IN_FRAMES, 0)

	autoplay_level = 0

	assert(debug_reset_counts())
end

-- Initialize starfield layers.
local function init_starfield()
	assert(debug_log("init_starfield started"))
	local width <const> = STAR_SIZE // STAR_TILE_SIZE
	local cell_count <const> = width * width

	local base_cells = table.create(cell_count, 0)
	local cells = table.create(cell_count, 0)

	starfield = table.create(16, 0)
	for layer = 1, 16, 4 do
		-- Initialize base set of cells for each layer.  This assigns star
		-- variations for each cell, and also animation variations for
		-- each frame.  To reduce number of calls to rand(), the cell values
		-- are encoded as follows:
		-- bits 0..1 = variation for frame 0
		-- bits 2..3 = variation for frame 1
		-- bits 4..5 = variation for frame 2
		-- bits 6..7 = variation for frame 3
		-- bits 8..12 = star variation.
		for i = 1, cell_count do
			base_cells[i] = rand(0, 0xfff)
		end

		for frame = 0, 3 do
			starfield[layer + frame] = gfx.tilemap.new()
			starfield[layer + frame]:setImageTable(stars)

			-- Initialize tile indices for a single frame.
			for i = 1, cell_count do
				local base_variation <const> = base_cells[i] >> 8
				local frame_variation <const> = (base_cells[i] >> (frame * 2)) & 3
				if base_variation >= STAR_VARIATION_COUNT or frame_variation == 3 then
					-- Cell is either permanently empty space (6/16 chance),
					-- or it's empty for current frame (1/4 chance).
					cells[i] = -1
					assert(debug_count("star_empty"))
				else
					-- Cell contains a visible star.  Either use the small dot
					-- variant (2/4 chance) or the cross variant (1/4 chance).
					cells[i] = base_variation * 2 + 1 + (frame_variation >> 1)
					assert(cells[i] >= 1)
					assert(cells[i] <= ({stars:getSize()})[1])
					assert(debug_count((frame_variation >> 1) == 1 and "star_cross" or "star_dot"))
				end
			end
			starfield[layer + frame]:setTiles(cells, width)
		end
	end

	inverted_starfield = gfx.image.new(400, 240)
	inverted_starfield:setInverted(true)
	assert(debug_log("init_starfield done"))
	assert(debug_log_counts())
end

-- Draw a single set of starfield tiles at a particular offset.
local function draw_star_layer(star_tiles, x, y)
	assert(star_tiles)
	assert(type(x) == "number")
	assert(type(y) == "number")
	assert(x >= 0 and x < STAR_SIZE and x == floor(x))
	assert(y >= 0 and y < STAR_SIZE and y == floor(y))

	if x < 400 then
		if y < 240 then
			star_tiles:draw(x - STAR_SIZE, y - STAR_SIZE)
			star_tiles:draw(x - STAR_SIZE, y)
			star_tiles:draw(x, y - STAR_SIZE)
			star_tiles:draw(x, y)
			assert(debug_count("star_split4"))
		else
			star_tiles:draw(x - STAR_SIZE, y - STAR_SIZE)
			star_tiles:draw(x, y - STAR_SIZE)
			assert(debug_count("star_split2h"))
		end
	else
		if y < 240 then
			star_tiles:draw(x - STAR_SIZE, y - STAR_SIZE)
			star_tiles:draw(x - STAR_SIZE, y)
			assert(debug_count("star_split2v"))
		else
			star_tiles:draw(x - STAR_SIZE, y - STAR_SIZE)
			assert(debug_count("star_split0"))
		end
	end
end

-- Draw starfield based on camera offset.
local function draw_starfield()
	-- global_frames decides which layers will be drawn.  To maximize glitter
	-- variations, the four sets of layers are all advanced on different frames.
	--
	-- base_frame        0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
	-- layer_index[1]    1  1  1  1  2  2  2  2  3  3  3  3  4  4  4  4
	-- layer_index[2]    5  5  6  6  6  6  7  7  7  7  8  8  8  8  5  5
	-- layer_index[3]    9 10 10 10 10 11 11 11 11 12 12 12 12  9  9  9
	-- layer_index[4]   13 13 13 14 14 14 14 15 15 15 15 16 16 16 16 13
	local base_frame <const> = (global_frames // 2) & 15
	local layer_index <const> =
	{
		(base_frame >> 2) + 1,
		(((base_frame + 2) >> 2) & 3) + 5,
		(((base_frame + 3) >> 2) & 3) + 9,
		(((base_frame + 1) >> 2) & 3) + 13,
	}

	-- Draw layers from bottom to top, moving from slower speeds to higher
	-- speeds.  The offset calculation has a few notable components:
	--
	-- camera_{x,y} multiplied by -i / (i + 1)
	--
	--    Each layer moves at slightly higher speed than the layer below.
	--    Also, the speed differences are not integer multiples of each other
	--    to maximize parallax effect.
	--
	-- dx += i, dy += 2*i
	--    Origin of each layer is a few pixels off to minimize star overlaps.
	--
	-- offset += STAR_SIZE // 2
	--    Origin of each layer is shifted by half of the maximum tilemap size.
	--    This is because initial origin for (camera_x, camera_y) is at (0,0),
	--    and all movements tend to center around this origin, which means we
	--    end up having to draw each tilemap multiple times to create the
	--    wraparound effect.  By shifting the tilemap origins to be further
	--    away, we minimize the likelihood of crossing tilemap seams.
	for i = 1, 4 do
		assert(STAR_SIZE - 1 == 0x3ff)
		local dx <const> = (floor(camera_x * -i / (i + 1)) + i + STAR_SIZE // 2) & 0x3ff
		local dy <const> = (floor(camera_y * -i / (i + 1)) + 2 * i + STAR_SIZE // 2) & 0x3ff
		draw_star_layer(starfield[layer_index[i]], dx, dy)
	end
end

-- Draw inverted starfield.
local function draw_inverted_starfield()
	assert(inverted_starfield)
	gfx.pushContext(inverted_starfield)
		gfx.clear(gfx.kColorBlack)
		draw_starfield()
	gfx.popContext()
	inverted_starfield:draw(0, 0)
end

-- Lazily initialize a single target and populate its screen coordinates,
-- returning the initialized target.
--
-- Most access to a single target go through init_target, so targets spring
-- out of existence on-demand.  Calling init_target repeatedly for the same
-- target incurs some unnecessary work in computing on-screen coordinates,
-- but the impact appears to be negligible.
local function init_target(x, y)
	assert(type(x) == "number")
	assert(type(y) == "number")
	assert(x == floor(x))
	assert(y == floor(y))
	assert((x % (TARGET_X_SPACING * 2) == 0 and y % TARGET_Y_SPACING == 0) or (x % (TARGET_X_SPACING * 2) == TARGET_X_SPACING and y % TARGET_Y_SPACING == TARGET_Y_SPACING // 2))
	assert(target)
	if not target[x] then
		assert(debug_count("add_column"))
		target[x] = {}
	end
	local column = target[x]

	if not column[y] then
		assert(debug_count("add_cell"))
		assert(BIT_TABLE[game_mode])
		column[y] =
		{
			-- See generate_bit_table.pl on value generation.
			value = BIT_TABLE[game_mode][rand(BIT_TABLE_SIZE[game_mode])],
			variation = rand(3, 32),
			motion = rand(1, DRIFT_OFFSET_COUNT),
			motion_phase = rand(1, DRIFT_FRAME_COUNT),
			selected = TARGET_UNSELECTED,
			birth_frame = global_frames,
			birth_variation = rand(0, 7)
		}
	end

	-- Compute screen coordinates.  We do this instead of using setDrawOffset
	-- since we need to compute offsets for the drift motions anyways, and
	-- doing it this way simplifies parallax drawing.
	--
	-- Also, we do this inside init_target instead of draw_target so that
	-- we can compute coordinate values without drawing.  This is needed
	-- to get the correct drawing order with connecting lines and targets.
	local t = column[y]
	local drift <const> = DRIFT_OFFSET[t.motion][(global_frames - t.birth_frame + t.motion_phase) % DRIFT_FRAME_COUNT + 1]
	t.sx = x - camera_x + SCREEN_CENTER_X + drift[1]
	t.sy = y - camera_y + SCREEN_CENTER_Y + drift[2]
	return t
end

-- Draw a single target.
local function draw_target(x, y)
	assert(type(x) == "number")
	assert(type(y) == "number")
	local t <const> = init_target(x, y)
	assert(t.sx)
	assert(t.sy)

	-- Draw selection cursor.
	if t.selected == TARGET_COMMITTED then
		sprite:drawImage(2, t.sx - SPRITE_HALF_WIDTH, t.sy - SPRITE_HALF_HEIGHT)
	end

	if t.value == 0 then
		-- Draw special sprite.
		sprite:drawImage(t.variation, t.sx - SPRITE_HALF_WIDTH, t.sy - SPRITE_HALF_HEIGHT)
	else
		-- Draw value.
		local d0y <const> = t.sy - LARGE_DIGIT_HALF_HEIGHT
		local b = 1
		if t.selected == TARGET_COMMITTED then
			b = 17
		end
		if all_ones == 0xf then
			local d0x <const> = t.sx - LARGE_DIGIT_HALF_WIDTH
			assert(t.value <= 15)
			large_digit[t.value + b]:draw(d0x, d0y)
		else
			local d0x <const> = t.sx - LARGE_DIGIT_WIDTH
			large_digit[(t.value >> 4) + b]:draw(d0x, d0y)
			large_digit[(t.value & 15) + b]:draw(d0x + LARGE_DIGIT_WIDTH, d0y)
		end
	end
end

-- Draw birth animation over newly created targets.
local function draw_birthmark(x, y)
	assert(type(x) == "number")
	assert(type(y) == "number")

	-- Avoid calling init_target again.  Target is guaranteed to be initialized
	-- since draw_target would have been called for this target earlier.
	assert(target[x])
	assert(target[x][y])
	local t <const> = target[x][y]
	assert(t.sx)
	assert(t.sy)

	local age <const> = global_frames - t.birth_frame
	if age < 16 then
		local i <const> = t.birth_variation * 16 + age + 33
		sprite:drawImage(i, t.sx - SPRITE_HALF_WIDTH, t.sy - SPRITE_HALF_HEIGHT)
	end
end

-- Draw targets near the viewport center.
local function draw_visible_targets(draw_func)
	assert(type(draw_func) == "function")
	local aligned_x <const> = camera_x - (camera_x % TARGET_X_SPACING)
	local aligned_y <const> = camera_y - (camera_y % TARGET_Y_SPACING)
	assert(aligned_x % TARGET_X_SPACING == 0)
	assert(aligned_y % TARGET_Y_SPACING == 0)

	for x = aligned_x - DRAW_HALF_WIDTH,
	        aligned_x + DRAW_HALF_WIDTH,
	        TARGET_X_SPACING do
		if x % (TARGET_X_SPACING * 2) == 0 then
			-- Draw even columns.
			for y = aligned_y - DRAW_EVEN_HALF_HEIGHT,
			        aligned_y + DRAW_EVEN_HALF_HEIGHT,
			        TARGET_Y_SPACING do
				draw_func(x, y)
			end
		else
			-- Draw odd columns.
			for y = aligned_y - DRAW_ODD_HALF_HEIGHT,
			        aligned_y + DRAW_ODD_HALF_HEIGHT,
			        TARGET_Y_SPACING do
				draw_func(x, y)
			end
		end
	end
end

-- Draw lines connecting targets within selection.
local function draw_lines_connecting_selection()
	local length <const> = #current_chain
	if length < 2 then
		return
	end

	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(1)
	local start <const> = init_target(current_chain[1][1], current_chain[1][2])
	assert(start)
	local x = start.sx
	local y = start.sy
	for i = 2, length do
		local t <const> = init_target(current_chain[i][1], current_chain[i][2])
		gfx.drawLine(x, y, t.sx, t.sy)
		x = t.sx
		y = t.sy
	end
end

-- Draw hint lines.
local function draw_solution_path(path)
	assert(type(path) == "table")

	-- Check that current chain matches the solution path.  If it has
	-- already diverged, we don't want to draw hint lines because they
	-- will interfere with current chain line.
	assert(current_chain)
	local length <const> = min(#current_chain, #path)
	for i = 1, length do
		if current_chain[i][1] ~= path[i][1] or current_chain[i][2] ~= path[i][2] then
			return
		end
	end

	local t = init_target(path[1][1], path[1][2])
	local x = t.sx
	local y = t.sy
	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(1)
	for i = 2, #path do
		t = init_target(path[i][1], path[i][2])
		gfx.drawLine(x, y, t.sx, t.sy)
		x = t.sx
		y = t.sy
	end
end

-- Draw cursor pointing at next target.
local function draw_next_target()
	assert(next_target_direction >= 0)
	assert(next_target_direction < 360)
	local p <const> = CURSOR_POLY[next_target_direction]
	assert(p)
	local cx <const> = target[cursor_x][cursor_y].sx
	local cy <const> = target[cursor_x][cursor_y].sy
	local x0 <const> = cx + p[1]
	local y0 <const> = cy + p[2]
	local x1 <const> = cx + p[3]
	local y1 <const> = cy + p[4]
	local x2 <const> = cx + p[5]
	local y2 <const> = cy + p[6]

	local i <const> = (next_target_direction + 30) // 60
	assert(TARGET_OFFSET[i])
	local tx <const> = cursor_x + TARGET_OFFSET[i][1]
	local ty <const> = cursor_y + TARGET_OFFSET[i][2]

	-- In theory, all targets that are immediate neighbors of current target
	-- must already exist, since the screen is arranged so that current target
	-- is at least two steps from the visible edge, and we initialized all
	-- targets that are visible.  That said, it's conceivable that players
	-- advancing rapidly may be able to reach an uninitialized target before
	-- screen scrolling has caught up.  To be safe, we force initialize the
	-- next target here.
	local t <const> = init_target(tx, ty)

	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(1)
	if #current_chain >= MAX_CHAIN_LENGTH or t.selected == TARGET_COMMITTED then
		-- Draw hollow triangle if target is not available, either because
		-- the chain has already reached maximum length, or because target
		-- is already part of current chain.
		gfx.drawTriangle(x0, y0, x1, y1, x2, y2)
	else
		-- Draw solid triangle if target is available.
		gfx.fillTriangle(x0, y0, x1, y1, x2, y2)

		-- Also highlight next target.
		sprite:drawImage(1, target[tx][ty].sx - SPRITE_HALF_WIDTH, target[tx][ty].sy - SPRITE_HALF_HEIGHT)
	end
end

-- Draw table of XOR result.
local function draw_xor_result()
	gfx.setColor(gfx.kColorBlack)
	gfx.setDitherPattern(0.5)

	-- Draw background rectangle to make the dot display stand out better.
	--
	-- We don't necessarily have to draw this, and we don't necessarily need
	-- the extra lines of code to match the result height (we can just always
	-- add 3 even if preview dots won't be drawn).  But it's just a bit of
	-- extra polish that's nice to have.
	local chain_length <const> = #current_chain
	local result_height = chain_length + 2
	if chain_length < MAX_CHAIN_LENGTH then
		local d <const> = TARGET_OFFSET[(next_target_direction + 30) // 60]
		local t <const> = init_target(cursor_x + d[1], cursor_y + d[2])
		if t.selected == TARGET_UNSELECTED then
			result_height += 3
		end
	end
	if all_ones == 0xf then
		gfx.fillRect(400 - DOTS_WIDTH - 6, 0, DOTS_WIDTH + 6, result_height * DOTS_HEIGHT + 6)
	else
		gfx.fillRect(400 - DOTS_WIDTH * 2 - 6, 0, DOTS_WIDTH * 2 + 6, result_height * DOTS_HEIGHT + 6)
	end

	xor_result:draw(400 - DOTS_WIDTH * 2 - 3, 3)
end

-- Score display.
local function draw_score()
	if score == 0 then
		return
	end

	-- Select character set based on last completed chain.
	assert(last_completed_xor_result == 0 or last_completed_xor_result == all_ones)
	local base <const> = last_completed_xor_result == 0 and 1 or 20

	-- Fill score tilemap from right to left.
	local d = 11
	local s = score
	while s ~= 0 do
		score_display:setTileAtPosition(d, 1, base + (s & 15))
		s >>= 4
		d -= 1
	end

	-- Add prefix.
	d -= 2
	score_display:setTileAtPosition(d + 1, 1, base)       -- '0'
	score_display:setTileAtPosition(d + 2, 1, base + 16)  -- 'x'

	-- Draw score with negative X offset, such that the "0x" prefix
	-- is aligned near the left edge of the screen (plus some margin).
	--
	-- Note that we didn't populate all cells to the left of the "0x"
	-- prefix.  This is because score length never decreases, and we
	-- reset all cells to empty inside reset() function, so all
	-- unmodified cells to the left of "0x" will be empty.
	score_display:draw(d * -SMALL_DIGIT_WIDTH + 3, 3)
end

-- High score display.
local function draw_high_score()
	assert(persistent_state[SAVE_STATE_SCORES])
	assert(persistent_state[SAVE_STATE_SCORES][game_mode])
	local high_score = persistent_state[SAVE_STATE_SCORES][game_mode]
	if high_score <= 0 then
		return
	end

	-- Count number of digits.
	local digit_count = 8
	for i = 1, 7 do
		if high_score < (1 << (i * 4)) then
			digit_count = i
			break
		end
	end

	-- Populate tilemap.
	local cells =
	{
		18, 19,  -- "HI"
		-1,      -- space
		1, 17,   -- "0x"
		-1, -1, -1, -1, -1, -1, -1, -1
	}
	local d = 5 + digit_count
	while high_score > 0 do
		cells[d] = (high_score & 15) + 1
		high_score >>= 4
		d -= 1
	end
	assert(#cells == 13)
	high_score_display:setTiles(cells, 13)
	high_score_display:draw(200 - (5 + digit_count) * 4, 3)
end

-- Time display.
local function draw_time_remaining()
	assert(thinking_time <= ENDGAME_HARD_LIMIT)

	-- Draw growing white rectangle at bottom of screen.  Draw the rectangle
	-- at 2 pixels thick if user has been idle for more than a few seconds,
	-- otherwise draw it at 1 pixel thick.  The transition highlights when
	-- thinking time consumption becomes super-linear because user has been
	-- idle for too long (see update_game_time function).
	gfx.setColor(gfx.kColorWhite)
	if global_frames - last_action_timestamp > 150 then
		gfx.fillRect(0, 238, 400 * thinking_time / ENDGAME_HARD_LIMIT, 2)
	else
		gfx.fillRect(0, 239, 400 * thinking_time / ENDGAME_HARD_LIMIT, 1)
	end

	-- Fade screen to white.
	if thinking_time > ENDGAME_LOW_WATERMARK then
		local alpha <const> = (thinking_time - ENDGAME_LOW_WATERMARK) / (ENDGAME_HARD_LIMIT - ENDGAME_LOW_WATERMARK)
		gfx.setDitherPattern(1.0 - alpha, gfx.image.kDitherTypeBayer8x8)
		gfx.fillRect(0, 0, 400, 240)
	end
end

-- Update in-game clocks for game_loop.
local function update_game_time()
	global_frames += 1

	local consecutive_idle_time <const> = global_frames - last_action_timestamp

	-- First few frames of thinking time is free for first ~80% of the game.
	-- This means if a player moves really fast, they can play indefinitely.
	-- This is so that game runs forever when autoplay is enabled.
	--
	-- Because first few frames are discounted, total game time would be:
	--
	--   action count * (average time per turn - FAST_THINK_THRESHOLD)
	--
	-- ENDGAME_HARD_LIMIT has been set so that typical game lasts about
	-- 300 seconds, assuming that player performs about one action per second.
	--
	-- In the last 20% of the game when thinking_time has reached
	-- ENDGAME_LOW_WATERMARK, the first few frames are no longer free.
	-- This means once the screen has start fading to white, mashing buttons
	-- rapidly isn't going to stop it.
	if consecutive_idle_time < FAST_THINK_THRESHOLD and
	   thinking_time < ENDGAME_LOW_WATERMARK then
		return
	end

	-- First 5 second of think time decreases at normal rate.
	if consecutive_idle_time <= 150 then
		thinking_time += 1
		return
	end

	-- Next 15 seconds decreases at an increasing rate, so that being
	-- idle for ~20 seconds causes all thinking time to be exhausted.
	-- 20 seconds seems like a good threshold, we have tried 30 seconds
	-- previously and it just felt too long.
	--
	-- ENDGAME_HARD_LIMIT = (600 + 150) * multiplier * (600 - 150) / 2
	local multiplier <const> = ENDGAME_HARD_LIMIT * 2 / ((600 + 150) * (600 - 150))
	thinking_time += multiplier * consecutive_idle_time
end

-- Check if a target is an immediate neighbor of current cursor position,
-- returns true if so.
--
-- We could also add a field to each target to mark immediate neighbors
-- of the starting cell, which will allow us to eliminate this function.
-- Benchmark shows roughly no change in performance, so we are keeping this
-- function call to avoid having to store and update an extra field.
local function is_immediate_neighbor(x, y)
	assert(type(x) == "number")
	assert(type(y) == "number")

	for i = 0, 5 do
		local d <const> = TARGET_OFFSET[i]
		assert(d)
		if cursor_x + d[1] == x and cursor_y + d[2] == y then
			return true
		end
	end
	return false
end

-- Copy path to solution_path_0.
local function populate_solution_path_0(path, depth)
	assert(type(path) == "table")
	assert(type(depth) == "number")

	solution_path_0 = table.create(depth, 0)
	for i = 1, depth do
		solution_path_0[i] = {path[i][1], path[i][2]}
	end
end

-- Copy path to solution_path_f.
local function populate_solution_path_f(path, depth)
	assert(type(path) == "table")
	assert(type(depth) == "number")

	solution_path_f = table.create(depth, 0)
	for i = 1, depth do
		solution_path_f[i] = {path[i][1], path[i][2]}
	end
end

-- Modify target at (x,y) to complete a path.
local function complete_path(path, depth, value, goal_target)
	assert(type(path) == "table")
	assert(type(depth) == "number")
	assert(type(value) == "number")
	assert(type(goal_target) == "table")

	goal_target.maze_generation = global_frames

	if not solution_path_0 then
		goal_target.value = value
		populate_solution_path_0(path, depth)
		return
	end

	assert(not solution_path_f)
	goal_target.value = all_ones ~ value
	populate_solution_path_f(path, depth)
end

-- Recursively initialize two solution paths.  Returns true if both solution
-- paths have been found.
--
-- This game is basically continuously creating mazes starting from the
-- center of the screen, such that XOR of all values along the shortest
-- paths from the start to the two goals will result in 0x0 or 0xf.  The
-- maze is generated by a randomized depth-first search, with the ending
-- condition being one of the following:
--
-- 1. Sum along the path is either 0x0 or 0xf.
-- 2. Path has reached a previously empty target.
-- 3. Cursor has reached outside of the screen.
--
-- For #2 and #3, we will insert an appropriate value at the new spot to
-- complete the chain.
--
-- #2 can happen if a target just got removed as part of a completed chain.
-- It also happens at the beginning of the game when the grid is empty.
-- Because of the empty grid condition, it's very likely that there will be
-- a chain of length 2 available at the beginning of the game, unless the
-- starting position happens to be surrounded by targets with zero values.
--
-- Arguments:
--  path = current path, possibly with trailing elements.
--  depth = true length of current path.
--  value = XOR of all values before the final target.
local function generate_solutions(path, depth, value)
	assert(type(path) == "table")
	assert(type(depth) == "number")
	assert(type(value) == "number")

	local x <const> = path[depth][1]
	local y <const> = path[depth][2]
	local t = init_target(x, y)

	-- Return early if current target has already been visited in the current
	-- cycle of generate_solutions().
	if t.maze_generation and t.maze_generation == global_frames then
		return false
	end

	-- Try modifying current target to complete a chain.
	if depth > 1 and (not is_immediate_neighbor(x, y)) then
		if t.birth_frame == global_frames then
			-- This is a newly created target, and it's the first time that
			-- generate_solutions has touched it, so we can replace its value
			-- with whatever we want to complete a path.
			complete_path(path, depth, value, t)

			-- Do not expand from this target.  The chain would be completed
			-- the moment player visits this target, so player won't be able
			-- to expand beyond this spot.
			return solution_path_0 and solution_path_f

		else
			-- This is an existing target.
			if (abs(x - path[1][1]) >= SCREEN_CENTER_X + TARGET_X_SPACING // 2) or
				(abs(y - path[1][2]) >= SCREEN_CENTER_Y + TARGET_Y_SPACING // 2) then
				-- This target is outside of visible area, which means we can modify
				-- its value to complete a path, and player should not notice.
				complete_path(path, depth, value, t)
				return solution_path_0 and solution_path_f
			end
		end
	end

	-- Mark the target as visited so that future depth-first search will
	-- not expand from this target.
	--
	-- This marking is done with the current global clock.  This is so that
	-- generate_solutions() can treat targets marked by earlier calls as
	-- unmarked, since their maze_generation will be older.
	t.maze_generation = global_frames

	-- Check if all values up to current target forms a complete chain.  If so,
	-- we will stop further expansion since player won't be able to expand the
	-- chain beyond this target.
	--
	-- If there are multiple solutions available due to new solution found
	-- here and previously manufactured solution via complete_path, we will
	-- prefer the existing solution.  This is purely for efficiency reasons:
	-- since we have already got a solution, we don't need to spend time
	-- copying another one.
	--
	-- For scoring purposes, the solutions generated/found by this function
	-- are not guaranteed to be best or worst.  This function merely guarantees
	-- that solutions to both 0x0 and 0xf will exist, but makes no guarantees
	-- regarding their length being optimally long or short.  That said, the
	-- solutions found by this function will tend to be on the short side,
	-- because we have greedily picked the first available paths via depth-first
	-- search.
	--
	-- For players intended on finding solutions quickly, a simple strategy
	-- is to just keep going straight and that would usually work, at least
	-- in 4bit modes.  For players intended on scoring big, it takes a bit
	-- more care to ensure that the chains always end with 0x0 or 0xf to
	-- get the score multiplier, but starting with a few random steps to
	-- increase chain length is still a good idea.  Either way, following
	-- the solution hints is not the best scoring strategy.
	value = value ~ t.value
	if value == 0 then
		if not solution_path_0 then
			populate_solution_path_0(path, depth)
		end
		return solution_path_f
	elseif value == all_ones then
		if not solution_path_f then
			populate_solution_path_f(path, depth)
		end
		return solution_path_0
	end

	-- Random depth-first search.
	if depth < MAX_CHAIN_LENGTH then
		local direction <const> = PERMUTATIONS6[rand(PERMUTATIONS6_COUNT)]
		assert(direction)
		assert(#direction == 6)
		local next_position = table.create(2, 0)
		path[depth + 1] = next_position
		for i = 1, 6 do
			next_position[1] = x + TARGET_OFFSET[direction[i]][1]
			next_position[2] = y + TARGET_OFFSET[direction[i]][2]
			if generate_solutions(path, depth + 1, value) then
				return true
			end
		end
	end
	return false
end

-- Confirm that there are no solutions of length 1 or 2.
local function no_trivial_solutions()
	-- Check for solutions of length 1 (center cell is 0x0 or 0xf).
	assert(target[cursor_x])
	assert(target[cursor_x][cursor_y])
	local center <const> = target[cursor_x][cursor_y]
	if center.value == 0 or center.value == all_ones then
		debug_log(string.format("Bad center (%d,%d):%x", cursor_x, cursor_y, center.value))
		return false
	end

	-- Check for solutions of length 2 (center xor immediate neighbor).
	for i = 0, 5 do
		local d <const> = TARGET_OFFSET[i]
		assert(d)
		local nx <const> = cursor_x + d[1]
		local ny <const> = cursor_y + d[2]
		assert(target[nx])
		assert(target[nx][ny])
		local neighbor <const> = target[nx][ny]
		if center.value == neighbor.value or
		   (center.value ~ neighbor.value == all_ones) then
			debug_log(string.format("Bad neighbor (%d,%d):%x -> (%d,%d):%x", cursor_x, cursor_y, center.value, nx, ny, neighbor.value))
			return false
		end
	end

	return true
end

-- Create chains near current cursor position, and reset player chain.
local function init_chains()
	assert((1 <= game_mode and game_mode <= 4 and all_ones == 0xf) or (5 <= game_mode and game_mode <= 8 and all_ones == 0xff))

	-- Make sure all immediate neighbors of current cursor position is populated.
	for i = 0, 5 do
		local offset <const> = TARGET_OFFSET[i]
		init_target(cursor_x + offset[1], cursor_y + offset[2])
	end

	-- Initialize target at cursor position.
	local center = init_target(cursor_x, cursor_y)
	assert(center)

	-- Adjust center value so that XOR of this value against any of its
	-- immediate neighbors does not result in 0x0 or 0xf.  This avoids
	-- creating chains that are too short.
	--
	-- This is done by adjusting just the lower 4 bits, by XORing those 4 bits
	-- with consecutive values.  See xor_center_neighbor_experiment.c for why
	-- this is guaranteed to work.
	--
	-- Because we only need to adjust 4 bits, this same code works in both
	-- 4bit and 8bit modes.
	for i = 0, 15 do
		local all_good = true
		for j = 0, 5 do
			local offset <const> = TARGET_OFFSET[j]
			assert(offset)
			local neighbor = init_target(cursor_x + offset[1], cursor_y + offset[2])
			local c <const> = center.value ~ i
			local v <const> = c ~ neighbor.value
			if c == 0 or c == all_ones or v == 0 or v == all_ones then
				all_good = false
				break
			end
		end
		if all_good then
			center.value = center.value ~ i
			break
		end
	end
	assert(no_trivial_solutions())

	-- Generate solutions from center.
	solution_path_0 = nil
	solution_path_f = nil
	local path = table.create(MAX_CHAIN_LENGTH, 0)
	path[1] = {cursor_x, cursor_y}
	generate_solutions(path, 1, 0)
	assert(solution_path_0)
	assert(solution_path_f)
	assert(no_trivial_solutions())

	-- Reset player chain to keep just the first position.
	current_chain = {{cursor_x, cursor_y}}
	center.selected = TARGET_COMMITTED
end

-- Prepare state for testing.
local function prepare_test_state()
	global_frames = 0
	cursor_x = 0
	cursor_y = 0
	camera_x = 0
	camera_y = 0
	target = {}
end

-- Cleanup state after tests.
local function cleanup_test_state()
	global_frames = nil
	cursor_x = nil
	cursor_y = nil
	camera_x = nil
	camera_y = nil
	target = nil
	solution_path_0 = nil
	solution_path_f = nil
	game_mode = nil
	all_ones = nil
end

-- Run init_chains repeatedly for testing.
local function debug_fuzz_init_chains()
	if not playdate.isSimulator then
		return true
	end

	prepare_test_state()
	for m = 1, 2 do
		if m == 1 then
			debug_log("debug_fuzz_init_chains started (4 bit)")
			game_mode = 3
			all_ones = 0xf
		else
			debug_log("debug_fuzz_init_chains started (8 bit)")
			game_mode = 7
			all_ones = 0xff
		end
		for i = 1, 1000 do
			-- Initialize grid.
			init_chains()

			-- Remove random targets from grid before next cycle.
			for x = cursor_x - DRAW_HALF_WIDTH,
					  cursor_x + DRAW_HALF_WIDTH,
					  TARGET_X_SPACING do
				if x % (TARGET_X_SPACING * 2) == 0 then
					for y = cursor_y - DRAW_EVEN_HALF_HEIGHT,
							  cursor_y + DRAW_EVEN_HALF_HEIGHT,
							  TARGET_Y_SPACING do
						if target[x] and target[x][y] and rand(4) == 1 then
							target[x][y] = nil
						end
					end
				else
					for y = cursor_y - DRAW_ODD_HALF_HEIGHT,
							  cursor_y + DRAW_ODD_HALF_HEIGHT,
							  TARGET_Y_SPACING do
						if target[x] and target[x][y] and rand(4) == 1 then
							target[x][y] = nil
						end
					end
				end
			end
			if target[cursor_x] then
				target[cursor_x][cursor_y] = nil
			end

			-- Update global clock.  We can't run two generation cycles in the
			-- same frame because we use the clock to mark which targets have
			-- already been visited.
			global_frames += 1
		end
	end

	debug_log("debug_fuzz_init_chains done")
	cleanup_test_state()
	return true
end
assert(debug_fuzz_init_chains())

-- Update XOR result display for next target preview, returning value of
-- current chain.
local function update_xor_preview(length)
	-- Get value of current chain.
	assert(type(length) == "number")
	assert(length == #current_chain)
	local value = 0
	local last_value = 0
	local last_position = nil
	for i = 1, length do
		last_position = current_chain[i]
		assert(target[last_position[1]][last_position[2]])
		last_value = target[last_position[1]][last_position[2]].value
		value = value ~ last_value
	end

	-- If the chain is complete, we don't need to do any of the tilemap updates,
	-- since we will rebuild it at the start of the next frame.
	if value == 0 or value == all_ones then
		return value
	end

	-- Add last value to table.
	xor_result:setTileAtPosition(2, length, (last_value & 0xf) + 1)

	-- Add separator followed by result for the current chain.
	-- This intermediate result is useful for players who are planning
	-- multiple steps ahead, since they can recognize patterns for
	-- number combinations that matches particular bit patterns.
	xor_result:setTileAtPosition(2, length + 1, 17)
	xor_result:setTileAtPosition(2, length + 2, (value & 0xf) + 1)

	-- Fetch next value.
	local d <const> = TARGET_OFFSET[(next_target_direction + 30) // 60]
	local next_t <const> = init_target(last_position[1] + d[1], last_position[2] + d[2])

	-- If chain is already too long, or next target is not accessible,
	-- don't show the preview value.
	local show_preview <const> = #current_chain < MAX_CHAIN_LENGTH and next_t.selected == TARGET_UNSELECTED

	-- Add next value, followed by separator, followed by preview result of
	-- current chain xor with next value.  This is useful for players who
	-- only plan one step ahead, since they can just look at this final
	-- preview value and decide whether the chain will be complete or not.
	local preview <const> = value ~ next_t.value
	if show_preview then
		xor_result:setTileAtPosition(2, length + 3, (next_t.value & 0xf) + 18)
		xor_result:setTileAtPosition(2, length + 4, 17)
		xor_result:setTileAtPosition(2, length + 5, (preview & 0xf) + 18)
	else
		xor_result:setTileAtPosition(2, length + 3, -1)
		xor_result:setTileAtPosition(2, length + 4, -1)
		xor_result:setTileAtPosition(2, length + 5, -1)
	end

	-- Add trailing blank cell.  This is needed to cleanup leftover entries
	-- after undo.
	xor_result:setTileAtPosition(2, length + 6, -1)

	-- Update first digit for 8bit modes.
	if all_ones == 0xff then
		xor_result:setTileAtPosition(1, length, ((last_value >> 4) & 0xf) + 1)
		xor_result:setTileAtPosition(1, length + 1, 17)
		xor_result:setTileAtPosition(1, length + 2, ((value >> 4) & 0xf) + 1)
		if show_preview then
			xor_result:setTileAtPosition(1, length + 3, ((next_t.value >> 4) & 0xf) + 18)
			xor_result:setTileAtPosition(1, length + 4, 17)
			xor_result:setTileAtPosition(1, length + 5, ((preview >> 4) & 0xf) + 18)
		else
			xor_result:setTileAtPosition(1, length + 3, -1)
			xor_result:setTileAtPosition(1, length + 4, -1)
			xor_result:setTileAtPosition(1, length + 5, -1)
		end
		xor_result:setTileAtPosition(1, length + 6, -1)
	end
	return value
end

-- Update all visuals for game_loop and game_demo states.
local function common_updates_for_game_loop()
	gfx.clear(gfx.kColorBlack)

	-- Initialize grid.
	if not solution_path_0 then
		init_chains()
		update_xor_preview(1)

		-- First 6 rows contain:
		-- 1. First value in chain (current_chain[1]).
		-- 2. Separator.
		-- 3. Result.
		-- 4. Preview
		-- 5. Separator.
		-- 6. Preview result.
		--
		-- We need to wipe leftover values from row 7 to end of table.
		assert(({xor_result:getSize()})[2] == MAX_CHAIN_LENGTH + 6)
		for y = 7, MAX_CHAIN_LENGTH + 6 do
			xor_result:setTileAtPosition(1, y, -1)
			xor_result:setTileAtPosition(2, y, -1)
		end
	end

	-- Converge camera toward cursor position.
	camera_x = (camera_x * 15 + cursor_x) / 16
	camera_y = (camera_y * 15 + cursor_y) / 16

	-- Draw hints with flashing lines.
	if hint_mode == HINTS_VISIBLE or (hint_mode == HINTS_DELAYED and global_frames - last_action_timestamp > 90) then
		local f <const> = global_frames % 3
		if f == 0 then
			draw_solution_path(solution_path_0)
		elseif f == 1 then
			draw_solution_path(solution_path_f)
		end
	end

	-- Draw everything.
	draw_starfield()
	draw_lines_connecting_selection()
	draw_visible_targets(draw_target)
	draw_visible_targets(draw_birthmark)
	draw_next_target()
	draw_xor_result()
	draw_score()
	draw_time_remaining()
end

-- Draw title text characters.
local function draw_title_text()
	if global_frames >= TITLE_FADE_IN_FRAMES then
		if global_frames >= TITLE_ANIMATION_FRAMES then
			-- Draw everything aligned with screen.
			title_background:draw(0, 0)
			for i = 1, TITLE_FADE_IN_FRAMES do
				title_char:drawImage(i, TITLE_TEXT_X, TITLE_TEXT_Y)
			end

			-- Draw circle around current selected level.
			gfx.setColor(gfx.kColorBlack)
			gfx.setLineWidth(2)
			gfx.drawCircleAtPoint(142 + 19 * game_mode, 167, 10)

			-- For game_title state only, draw popup showing bit count
			-- if a button was pressed recently.
			--
			-- We don't want to draw this for game_edit_score state because
			-- game_edit_score is entered on button press, so this popup
			-- will always show up on the first few frames while the level
			-- dialog rectangle is being animated.
			if global_frames - last_action_timestamp < 15 and
			   playdate.update == game_title then
				if game_mode <= 4 then
					mode_popups:drawImage(1, 150 + 19 * game_mode, 113)
				else
					mode_popups:drawImage(2, 150 + 19 * game_mode, 113)
				end
			end
			return
		end

		-- Draw all characters, scrolling upward.
		--
		-- Background is not drawn here.  One thought is to draw partial
		-- background and have it grow downwards, but since we only have so
		-- few animation frames, the growth comes out to be about 14 pixels
		-- per frame, which is largely indistinguishable from the background
		-- just pop in all at once.
		local y <const> = (TITLE_ANIMATION_FRAMES - max(global_frames, TITLE_FADE_IN_FRAMES + TITLE_WAIT_FRAMES)) * 2
		for i = 1, 16 do
			title_char:drawImage(i, TITLE_TEXT_X, TITLE_TEXT_Y + y)
		end
		return
	end

	-- Make a random character visible.
	local i = rand(0, 15)
	for j = 0, 15 do
		local c <const> = ((i + j) % 16) + 1
		if not title_char_visible[c] then
			title_char_visible[c] = true
			break
		end
	end

	-- Draw currently visible characters.
	--
	-- Note that we don't draw the background here, since background includes
	-- additional menu text.
	for i = 1, 16 do
		if title_char_visible[i] then
			title_char:drawImage(i, TITLE_TEXT_X, TITLE_TEXT_Y + TITLE_SCROLL_FRAMES * 2)
		end
	end
end

-- Update all visuals for game_title and game_edit_score states.
local function common_updates_for_game_title()
	-- Don't need to clear screen here since draw_inverted_starfield will
	-- redraw the whole screen.

	draw_inverted_starfield()
	draw_title_text()
	if global_frames >= TITLE_ANIMATION_FRAMES then
		draw_high_score()
	end

	-- Update camera position so that starfield scrolls in the background.
	if global_frames == 0 then
		-- Set random acceleration angle on first frame.
		title_camera_a = rand(360)
	end
	local a <const> = title_camera_a * math.pi / 180
	title_camera_vx += 0.1 * cos(a)
	title_camera_vy += 0.1 * sin(a)
	local v2 <const> = title_camera_vx * title_camera_vx + title_camera_vy * title_camera_vy
	if v2 > 64 then
		local v <const> = 8 / sqrt(v2)
		title_camera_vx *= v
		title_camera_vy *= v

		-- Change camera acceleration direction whenever maximum velocity
		-- is reached.
		title_camera_a += rand(-60, 60)
	end
	camera_x += title_camera_vx
	camera_y += title_camera_vy
end

-- Common updates for game_over and game_over_high_score states.
local function common_updates_for_game_over(high_score)
	gfx.clear(gfx.kColorWhite)

	local text_position = 102
	if high_score then
		gfx.drawTextAligned("New high score!", 200, 148, kTextAlignment.center)
		text_position = 80
	end

	-- Show some stats if player completed at least one chain.
	if completed_chain_count > 0 then
		gfx.drawTextAligned(
			string.format("Collected *0x%x* points", score),
			200, text_position, kTextAlignment.center)

		-- Show chain count if player completed at least 2 chains.  It's at
		-- least 2 chains so that we don't have to special case the singular
		-- "constellation" text, since that rarely happens anyways.
		if completed_chain_count > 1 then
			gfx.drawTextAligned(
				string.format("from *%d* constellations", completed_chain_count),
				200, text_position + 22, kTextAlignment.center)
		end
	else
		-- Show just game over text if player didn't complete any chains.
		gfx.drawTextAligned("*G A M E   O V E R*", 200, text_position + 11, kTextAlignment.center)
	end

	draw_score()
	draw_high_score()

	global_frames += 1

	-- Ignore all inputs in the first few frames of game over state,
	-- and don't draw "return to title" text until we are accepting inputs.
	--
	-- If we accepted inputs immediately upon entering game over state,
	-- players who were pressing buttons desperately in the last moments
	-- of endgame state might miss the game over screen, so we delay
	-- handling inputs for a bit.
	if global_frames < 15 then
		assert(debug_frame_rate())
		assert(debug_periodic_log())
		return
	end

	gfx.drawTextAligned("\u{24b6} *return to title*", 200, TITLE_HELP_TEXT_POSITION, kTextAlignment.center)

	-- Return to title screen on button press.
	if playdate.buttonJustPressed(playdate.kButtonA) or
	   playdate.buttonJustPressed(playdate.kButtonB) then
		reset(true)
	end

	assert(debug_frame_rate())
	assert(debug_periodic_log())
end

-- Syntactic sugar to adjust volume on all channels.
local function set_global_volume(volume)
	assert(type(volume) == "number")
	for i = 1, MAX_NOTE_CHANNELS do
		channel[i]:setVolume(volume)
	end
end

-- Play a note in response to advance/undo actions.
local function play_note()
	-- Select a random note to be played.
	--
	-- Random really works best here.  One alternative is to play the notes
	-- with a fixed sequence (e.g. {1,2,3,4}), which will make the sounds
	-- less random and better resemble a song.  Well, I have tried that and
	-- it didn't really work out, because the chain lengths are random.
	assert(NOTE_GROUPS[note_group_index])
	local group_size <const> = #NOTE_GROUPS[note_group_index]
	local n = rand(group_size)

	-- Make sure two consecutive notes are always different.  If we would
	-- have played the note that was same as the previous one, play the
	-- next note from the sequence.
	--
	-- This appear to sound better than other strategies, including
	-- + Simply allow all notes to play at equal probability, consecutive
	--   or not.
	-- + Resolve consecutive notes via complement (e.g. group_size + 1 - n)
	--   instead of moving up to the next note.
	if n == last_note_index then
		n = n % group_size + 1
	end
	assert(NOTE_GROUPS[note_group_index][n])

	-- Play this note on the channel corresponding to the note index.
	-- This is so that different notes will be played on different channels,
	-- while same notes will stop earlier playing notes.
	assert(n <= #celesta)
	celesta[n]:play(1, RATE_MULTIPLIER[NOTE_GROUPS[note_group_index][n] + 1])
	last_note_index = n
end

-- Check for completed chain and update scores accordingly.
local function check_completed_chain(length)
	assert(type(length) == "number")

	-- Get current chain value.
	local value <const> = update_xor_preview(length)
	if value ~= 0 and value ~= all_ones then
		-- Did not complete a chain.  Play a random note from current group.
		play_note()
		return
	end

	-- Completed a chain.  Play all notes in the current group.
	local group_size <const> = #NOTE_GROUPS[note_group_index]
	assert(group_size <= #celesta)
	for n = 1, group_size do
		celesta[n]:play(1, RATE_MULTIPLIER[NOTE_GROUPS[note_group_index][n] + 1])
	end

	-- Advance group index.
	note_group_index = note_group_index % #NOTE_GROUPS + 1

	-- Increment multiplier for consecutive chains of the same result type.
	if value == last_completed_xor_result then
		if score_multiplier < 4 then
			score_multiplier += 1
		end
	else
		last_completed_xor_result = value
		score_multiplier = 1
	end

	-- Remove entries from completed chain, and also check for extra bonus.
	--
	-- Extra bonus is awarded if "Bocchi" or "Kita" appears on the chain.
	-- 3x for each, 9x for both.  This happens due to two subconscious
	-- implementation choices:
	--
	-- + Targets with zeroes deserve special sprites because they are xor
	--   identities, and the first set of special sprites I drew were
	--   Bocchi and Kita (for no particular reason, really).
	--
	-- + List of circles connected by lines somewhat resembles a constellation.
	--
	-- Putting the two together, I realized that I was influenced by the song
	-- "If I Could be a Constellation".  I immediately implemented this bonus
	-- system, and changed the project name to "Xor Constellation".
	--
	-- Despite the gameplay involving making a series of constellations, the
	-- title uses singular "constellation" and not plural "constellations",
	-- just like the song title.
	local bocchi = 1
	local kita = 1
	assert(length >= 3)
	for i = 1, length do
		local x <const> = current_chain[i][1]
		local y <const> = current_chain[i][2]
		assert(target[x])
		assert(target[x][y])
		if target[x][y].value == 0 and target[x][y].variation <= 4 then
			assert(target[x][y].variation == 3 or target[x][y].variation == 4)
			if target[x][y].variation == 3 then
				bocchi = 3
			else
				kita = 3
			end
		end
		target[x][y] = nil
		assert(debug_count("remove_cell"))
	end

	-- Update chain counter.
	completed_chain_count += 1
	assert(debug_count("completed_chain"))
	assert(debug_count(string.format("z%02d", length)))

	-- Maximum change in score in a single step:
	--
	--   (1 << (24 - 3)) * 4 * 3 * 3 = 0x4800000 = 75497472
	--
	-- This means the delta itself won't overflow signed 32bits.
	assert(length >= 3)
	assert(length <= MAX_CHAIN_LENGTH)
	assert(score_multiplier <= 4)
	local delta <const> = (1 << (length - 3)) * score_multiplier * bocchi * kita
	assert(delta > 0)
	assert(delta <= 0x4800000)

	-- Avoid overflowing score.
	--
	-- The minimum number of chains needed to reach 0x7fffffff is about 30.
	-- To complete 30 maximum chains in ~300 seconds requires making one move
	-- every ~400 milliseconds, which is very difficult for humans, so this
	-- overflow is unlikely to happen.  But hey, you never know.
	local new_score <const> = score + delta
	if new_score <= 0 then
		assert(debug_log("score = " .. score .. " + " .. delta .. " = overflow"))
		score = 0x7fffffff
	else
		assert(debug_log("score = " .. score .. " + " .. delta .. " = " .. new_score))
		score = new_score
	end

	-- Regenerate targets at next update.
	solution_path_0 = nil
	solution_path_f = nil
end

-- Process input for enabling/disabling autoplay.  Returns true if game
-- should play itself randomly.
--
-- Autoplay is basically a fuzzing test for verifying grid generation and
-- chain updates.  The randomized modes work very well in 4 bit modes where
-- we can often complete chains out of pure luck.  In 8 bit modes we usually
-- not so lucky, but it's still fun to watch as a screensaver.  The "follow
-- hint" modes work equally well in 4 bit and 8 bit modes, and it's also used
-- to implement attract mode.
local function handle_autoplay()
	-- Check if any button was just pressed.  In steady state when no buttons
	-- are pressed, we don't change autoplay_level.
	if not (playdate.buttonJustPressed(playdate.kButtonUp) or
	        playdate.buttonJustPressed(playdate.kButtonDown) or
	        playdate.buttonJustPressed(playdate.kButtonLeft) or
	        playdate.buttonJustPressed(playdate.kButtonRight) or
	        playdate.buttonJustPressed(playdate.kButtonA) or
	        playdate.buttonJustPressed(playdate.kButtonB)) then
		return autoplay_level == AUTOPLAY_ENABLED
	end

	-- A button press was observed.  If autoplay is currently enabled,
	-- we will disable it now.
	if autoplay_level == AUTOPLAY_ENABLED then
		autoplay_level = 0
		assert(debug_log("autoplay disabled"))
		return false
	end

	-- Autoplay is currently disabled, but player has pressed all buttons of
	-- the required prefix sequence.  The last button press determines which
	-- autoplay mode will be used.
	if autoplay_level == #AUTOPLAY_BACKDOOR_SEQUENCE then
		if playdate.buttonJustPressed(playdate.kButtonUp) then
			autoplay_mode = AUTOPLAY_FOLLOW_HINT_ONE
			assert(debug_log("autoplay enabled: AUTOPLAY_FOLLOW_HINT_ONE"))
		elseif playdate.buttonJustPressed(playdate.kButtonDown) then
			autoplay_mode = AUTOPLAY_FOLLOW_HINT_ZERO
			assert(debug_log("autoplay enabled: AUTOPLAY_FOLLOW_HINT_ZERO"))
		elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
			autoplay_mode = AUTOPLAY_FOLLOW_HINT_LONG
			assert(debug_log("autoplay enabled: AUTOPLAY_FOLLOW_HINT_LONG"))
		elseif playdate.buttonJustPressed(playdate.kButtonRight) then
			autoplay_mode = AUTOPLAY_FOLLOW_HINT_ANY
			assert(debug_log("autoplay enabled: AUTOPLAY_FOLLOW_HINT_ANY"))
		elseif playdate.buttonJustPressed(playdate.kButtonB) then
			autoplay_mode = AUTOPLAY_RANDOM_AVOID_OBSTACLE
			assert(debug_log("autoplay enabled: AUTOPLAY_RANDOM_AVOID_OBSTACLE"))
		else
			assert(playdate.buttonJustPressed(playdate.kButtonA))
			autoplay_mode = AUTOPLAY_RANDOM
			assert(debug_log("autoplay enabled: AUTOPLAY_RANDOM"))
		end
		autoplay_level = AUTOPLAY_ENABLED
		return true
	end

	-- Autoplay is currently disabled.  Check for the expected button
	-- sequence to enable autoplay.
	if playdate.buttonJustPressed(AUTOPLAY_BACKDOOR_SEQUENCE[autoplay_level + 1]) then
		autoplay_level += 1
		assert(debug_log("autoplay_level = " .. autoplay_level))
		return false
	end

	-- Autoplay is currently disabled, and player pressed a button that
	-- did not match the expected sequence.  Reset autoplay_level to start
	-- matching from the beginning.
	autoplay_level = 0
	return false
end

-- Find the next target along the hint chain.  Returns the desired target
-- angle, or nil if all angles are bad and the appropriate action is undo.
local function autoplay_follow_hint(hint)
	assert(type(hint) == "table")

	-- Give up if current chain has already exceeded hint path.
	if #current_chain > #hint then
		return nil
	end

	for i = 1, #hint do
		if not current_chain[i] then
			-- All target positions matched so far, and current_chain is shorter
			-- than hint, so hint[i] is where we want to be.
			assert(i > 1)
			assert(cursor_x == current_chain[i - 1][1])
			assert(cursor_y == current_chain[i - 1][2])
			for j = 0, 5 do
				local d <const> = TARGET_OFFSET[j]
				if cursor_x + d[1] == hint[i][1] and cursor_y + d[2] == hint[i][2] then
					return j * 60
				end
			end
		end
		if current_chain[i][1] ~= hint[i][1] or current_chain[i][2] ~= hint[i][2] then
			-- Position mismatched.
			return nil
		end
	end

	-- current_chain matched hint exactly, but we still haven't completed
	-- this chain for some reason.  This should be unreachable.
	assert(false)
	return nil
end

-- Decide which direction to turn.  Updates next_target_direction.
local function autoplay_turn()
	local preferred_direction = nil

	if autoplay_mode == AUTOPLAY_FOLLOW_HINT_ZERO then
		preferred_direction = autoplay_follow_hint(solution_path_0)

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_ONE then
		preferred_direction = autoplay_follow_hint(solution_path_f)

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_LONG then
		if #solution_path_0 > #solution_path_f then
			preferred_direction = autoplay_follow_hint(solution_path_0)
		elseif #solution_path_0 < #solution_path_f then
			preferred_direction = autoplay_follow_hint(solution_path_f)
		else
			assert(#solution_path_0 == #solution_path_f)
			-- Since both solution paths are of equal length, prefer the same
			-- type that we followed last time to increase score_multiplier.
			if last_completed_xor_result == 0 then
				preferred_direction = autoplay_follow_hint(solution_path_0)
			else
				preferred_direction = autoplay_follow_hint(solution_path_f)
			end
		end

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_ANY then
		if rand(2) == 1 then
			preferred_direction = autoplay_follow_hint(solution_path_0)
			if not preferred_direction then
				preferred_direction = autoplay_follow_hint(solution_path_f)
			end
		else
			preferred_direction = autoplay_follow_hint(solution_path_f)
			if not preferred_direction then
				preferred_direction = autoplay_follow_hint(solution_path_0)
			end
		end

	elseif autoplay_mode == AUTOPLAY_RANDOM_AVOID_OBSTACLE then
		-- Start at a random direction, then keep turning clockwise until we find
		-- a direction that doesn't point at a selected target.
		local a = rand(0, 5)
		for i = 1, 6 do
			a = (a + 1) % 6
			local d <const> = TARGET_OFFSET[a]
			local t = init_target(cursor_x + d[1], cursor_y + d[2])
			if t.selected == TARGET_UNSELECTED then
				preferred_direction = a * 60
				break
			end
		end

	else
		-- Set purely random direction.
		preferred_direction = rand(0, 5) * 60
	end

	if preferred_direction then
		next_target_direction = preferred_direction
	end
end

-- Decide whether to go forward or backward.  Returns "advance, undo" pair.
local function autoplay_move()
	if autoplay_mode == AUTOPLAY_FOLLOW_HINT_ZERO then
		-- Advance if we are currently along the zero path, otherwise undo.
		if autoplay_follow_hint(solution_path_0) then
			return true, false
		end

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_ONE then
		-- Advance if we are currently along the one path, otherwise undo.
		if autoplay_follow_hint(solution_path_f) then
			return true, false
		end

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_LONG then
		-- Advance if we are currently along the preferred path, otherwise undo.
		if #solution_path_0 > #solution_path_f then
			if autoplay_follow_hint(solution_path_0) then
				return true, false
			end
		elseif #solution_path_0 < #solution_path_f then
			if autoplay_follow_hint(solution_path_f) then
				return true, false
			end
		else
			assert(#solution_path_0 == #solution_path_f)
			if last_completed_xor_result == 0 then
				if autoplay_follow_hint(solution_path_0) then
					return true, false
				end
			else
				if autoplay_follow_hint(solution_path_f) then
					return true, false
				end
			end
		end

	elseif autoplay_mode == AUTOPLAY_FOLLOW_HINT_ANY then
		-- Advance if we are currently on either solution path, otherwise undo.
		if autoplay_follow_hint(solution_path_0) or
		   autoplay_follow_hint(solution_path_f) then
			return true, false
		end

	elseif autoplay_mode == AUTOPLAY_RANDOM_AVOID_OBSTACLE then
		-- If next_target_direction points at unselected target:
		-- + Advance unconditionally if current chain has yet reached half
		--   of maximum length.
		-- + Otherwise, advance with decreasing probability proportional to
		--   chain length.
		--
		-- We need to start doing undos at increasing probability when the
		-- chain gets too long to avoid getting stuck near the end.
		--
		-- Note the ">" inequality comparison (as opposed to ">=").  When
		-- the chain is at maximum length, this condition will always fail,
		-- and we will always undo.
		if #current_chain < MAX_CHAIN_LENGTH // 2 or
		   rand(MAX_CHAIN_LENGTH) > #current_chain then
			local d <const> = TARGET_OFFSET[(next_target_direction + 30) // 60]
			assert(d)
			local t <const> = init_target(cursor_x + d[1], cursor_y + d[2])
			if t.selected == TARGET_UNSELECTED then
				return true, false
			end
		end

	else
		assert(autoplay_mode == AUTOPLAY_RANDOM)

		-- Advance or undo based on current chain length: prefer advance if chain
		-- chain is less than half of maximum length, otherwise prefer undo.
		if rand(MAX_CHAIN_LENGTH) > #current_chain then
			return true, false
		end
	end

	-- Undo.
	return false, true
end

-- React to user or demo input for game_loop and game_demo states.
local function commit_input(last_target_direction, advance_action, undo_action)
	assert(type(last_target_direction) == "number")
	assert(type(advance_action) == "boolean")
	assert(type(undo_action) == "boolean")

	-- Make sure next target angle is within range.
	assert(next_target_direction == floor(next_target_direction))
	assert(next_target_direction >= 0)
	if next_target_direction >= 360 then
		next_target_direction %= 360
	end

	-- A/Up: Advance to selected direction.
	local chain_length <const> = #current_chain
	if chain_length < MAX_CHAIN_LENGTH and advance_action then
		local d <const> = TARGET_OFFSET[(next_target_direction + 30) // 60]
		assert(d)
		local next_x <const> = cursor_x + d[1]
		local next_y <const> = cursor_y + d[2]
		local next_t = init_target(next_x, next_y)
		if next_t.selected == TARGET_UNSELECTED then
			next_t.selected = TARGET_COMMITTED
			current_chain[chain_length + 1] = {next_x, next_y, next_target_direction}
			assert(#current_chain == chain_length + 1)
			cursor_x = next_x
			cursor_y = next_y

			check_completed_chain(chain_length + 1)
			last_action_timestamp = global_frames

			-- Stop processing further input since we have already modified
			-- current_chain and cursor states.
			return
		end
	end

	-- B/Down: Undo.
	if chain_length > 1 and undo_action then
		-- If crank is docked, restore direction to whatever was used to
		-- reach the current target.  This means Down/B followed Up/A would
		-- be a no-op operation.
		--
		-- This is not done when crank is undocked, because direction is
		-- overwritten with absolute angle of the crank.  If we want to have
		-- the same behavior, we will either need to make crank handling not
		-- absolute, or change direction only on crank movements.  Neither
		-- feels really ideal.
		if playdate.isCrankDocked() then
			next_target_direction = current_chain[chain_length][3]
		end

		assert(current_chain[chain_length][1] == cursor_x)
		assert(current_chain[chain_length][2] == cursor_y)
		local t = init_target(cursor_x, cursor_y)
		assert(t.selected == TARGET_COMMITTED)
		t.selected = TARGET_UNSELECTED

		current_chain[chain_length] = nil
		assert(#current_chain == chain_length - 1)
		cursor_x = current_chain[chain_length - 1][1]
		cursor_y = current_chain[chain_length - 1][2]
		t = init_target(cursor_x, cursor_y)
		assert(t.selected == TARGET_COMMITTED)

		update_xor_preview(chain_length - 1)
		last_action_timestamp = global_frames

		-- Play a random note in current group.  This means players always
		-- get a sound whenever they move on to a different target, either
		-- forward or backward.
		--
		-- This makes the autoplay mode sound a lot more interesting.
		-- Previously we only play sounds for forward movements but not
		-- backward movements, and there would be a lot of silence when
		-- autoplay mode undoes a long chain.  Now the moments of silence
		-- only happen when an invalid move is attempted.
		--
		-- We could add sounds for those invalid moves as well, but we are
		-- keeping things as is since those occasional pauses seem to add more
		-- flavor (autoplay rhythm would be very regular otherwise).
		play_note()

		-- Stop processing further input since we have already modified
		-- current_chain and cursor states.
		return
	end

	-- If we got this far, it means none of the button presses modified
	-- cursor_chain and cursor states, which means we also haven't updated
	-- the XOR preview table yet.  If next target differs from previous
	-- selected target, we will need to update the preview table here.
	if (next_target_direction + 30) // 60 ~= last_target_direction then
		assert(chain_length == #current_chain)
		update_xor_preview(chain_length)
	end
end

-- Process input for game_loop state.
local function handle_input()
	local last_target_direction <const> = (next_target_direction + 30) // 60

	local advance_action = false
	local undo_action = false
	if handle_autoplay() then
		-- Game is under auto control.

		-- Perform action once every few frames.
		if (global_frames % AUTOPLAY_ACTION_PERIOD) ~= 0 then
			return
		end
		local t <const> = global_frames // AUTOPLAY_ACTION_PERIOD
		if (t & 1) == 0 then
			autoplay_turn()
		else
			advance_action, undo_action = autoplay_move()
		end

	else
		-- Game is under manual control.

		-- Set next target direction.
		if playdate.isCrankDocked() then
			-- Make sure direction is aligned to 60 degree increments.
			next_target_direction -= next_target_direction % 60
			if playdate.buttonJustPressed(playdate.kButtonLeft) then
				next_target_direction += 300
			elseif playdate.buttonJustPressed(playdate.kButtonRight) then
				next_target_direction += 60
			end
		else
			-- Set direction from crank angle.
			next_target_direction = floor(playdate.getCrankPosition())
		end

		-- Process button presses.
		advance_action =
			playdate.buttonJustPressed(playdate.kButtonUp) or
			playdate.buttonJustPressed(playdate.kButtonA)
		undo_action =
			playdate.buttonJustPressed(playdate.kButtonDown) or
			playdate.buttonJustPressed(playdate.kButtonB)
	end
	assert(next_target_direction == floor(next_target_direction))
	assert(next_target_direction >= 0)
	if next_target_direction >= 360 then
		next_target_direction %= 360
	end

	commit_input(last_target_direction, advance_action, undo_action)
end

-- Compute the delta from a to b in the range of [-180, 180).
local function angle_delta(a, b)
	assert(type(a) == "number")
	assert(type(b) == "number")

	if b < a then
		b += 360
	end

	local d = b - a
	if d < 180 then
		return d
	end
	return d - 360
end
assert(angle_delta(0, 0) == 0)
assert(angle_delta(90, 90) == 0)
assert(angle_delta(359, 359) == 0)
assert(angle_delta(0, 179) == 179)
assert(angle_delta(180, 359) == 179)
assert(angle_delta(181, 0) == 179)
assert(angle_delta(271, 90) == 179)
assert(angle_delta(0, 180) == -180)
assert(angle_delta(0, 359) == -1)
assert(angle_delta(1, 0) == -1)
assert(angle_delta(179, 0) == -179)
assert(angle_delta(269, 90) == -179)
assert(angle_delta(359, 180) == -179)
assert(angle_delta(89, 270) == -179)
assert(angle_delta(180, 0) == -180)
assert(angle_delta(270, 90) == -180)
assert(angle_delta(329, 149) == -180)
assert(angle_delta(90, 270) == -180)
assert(angle_delta(181, 0) == 179)
assert(angle_delta(271, 90) == 179)
assert(angle_delta(359, 178) == 179)
assert(angle_delta(89, 268) == 179)

-- Synthesize input for game_demo state.
local function demo_input()
	local last_target_direction <const> = (next_target_direction + 30) // 60

	-- Do nothing for the first 5 frames.
	if global_frames - last_target_direction < 5 then
		return
	end

	-- Decide on which direction to turn.  We will deterministically choose
	-- whichever path is shorter, breaking ties by choosing solution_path_0.
	-- This is roughly the opposite of AUTOPLAY_FOLLOW_HINT_LONG.
	local preferred_direction = nil
	if #solution_path_0 <= #solution_path_f then
		preferred_direction = autoplay_follow_hint(solution_path_0)
		assert(preferred_direction)
	else
		preferred_direction = autoplay_follow_hint(solution_path_f)
		assert(preferred_direction)
	end

	-- Turn toward the preferred direction at 8 degrees per frame.
	--
	-- We use a fixed turning speed for the demo.  We have also tried turning
	-- at a random variable rate, and the difference weren't all that
	-- noticeable, so fixed rate is good enough.
	local delta <const> = angle_delta(next_target_direction, preferred_direction)
	if abs(delta) < 8 then
		next_target_direction = preferred_direction
		if delta == 0 then
			-- If next_target_direction has matched preferred_direction exactly,
			-- we will randomly pause for a few frames before advancing forward.
			--
			-- The behavior we want is to have a short delay so that players
			-- watching the demo can see that the direction has changed, but
			-- we don't really want an extra state to track this short delay.
			-- Pausing randomly roughly accomplishes the desired behavior.
			if rand(4) == 1 then
				commit_input(last_target_direction, true, false)
			end
			return
		end

	else
		if delta > 0 then
			next_target_direction += 8
		else
			assert(delta < 0)
			next_target_direction -= 8
			if next_target_direction < 0 then
				next_target_direction += 360
			end
		end
	end

	-- Turn toward preferred direction.  Note that we never undo in demo mode,
	-- because we never stray from the solution path.
	commit_input(last_target_direction, false, false)
end

-- Validate a single integer from persistent_state.
local function is_valid_range(input, min_value, max_value)
	return input and type(input) == "number" and input == floor(input) and
			 min_value <= input and input <= max_value
end

-- Validate score table.
local function is_valid_scores()
	local input <const> = persistent_state[SAVE_STATE_SCORES]
	if not (input and type(input) == "table" and #input == 8) then
		return false
	end
	for i = 1, 8 do
		if not is_valid_range(input[i], 0, 0x7fffffff) then
			return false
		end
	end
	return true
end

-- Load saved state.
local function load_state()
	persistent_state = playdate.datastore.read()
	if not (persistent_state and
	        is_valid_range(persistent_state[SAVE_STATE_MODE], 1, 8) and
	        is_valid_range(persistent_state[SAVE_STATE_HINT], 1, 3) and
	        is_valid_scores()) then
		persistent_state =
		{
			[SAVE_STATE_MODE] = 3,  -- 4 bit, normal difficulty.
			[SAVE_STATE_HINT] = HINTS_DELAYED,
			[SAVE_STATE_SCORES] = {0, 0, 0, 0, 0, 0, 0, 0},
		}
		assert(debug_log("Using default state"))
	end

	-- Cache some commonly used values.
	game_mode = persistent_state[SAVE_STATE_MODE]
	hint_mode = persistent_state[SAVE_STATE_HINT]
	assert(debug_log("Initialized state: game_mode = " .. game_mode .. ", hint_mode = " .. hint_mode))
end

-- Save state to disk.
local function save_state()
	-- In the unlikely event that user requested the game to terminate before
	-- we have even loaded state, we will return early since there is nothing
	-- to save.
	if not persistent_state then
		return
	end

	persistent_state[SAVE_STATE_MODE] = game_mode
	persistent_state[SAVE_STATE_HINT] = hint_mode

	playdate.datastore.write(persistent_state)
	assert(debug_log("Saved state"))
end

-- When running on simulator in debug builds, we will save state on pause.
-- This makes it easier to debug issues related to saving state.
local function debug_save_state()
	if playdate.isSimulator then
		save_state()
	end
	return true
end

-- Play notes or chords from NOTE_GROUPS in a loop.
local function song_test()
	gfx.clear(gfx.kColorWhite)
	gfx.drawText("Song test", 4, 4)

	-- Show index of the last note or chord that was played.
	--
	-- This is done because the group/note indices are advanced right after
	-- playing a note or chord, so if we were to show the current group/note
	-- index, it will actually be the next note that will be played and not
	-- the note that we just heard.
	if song_test_last_note then
		gfx.drawText(song_test_last_note, 4, 36)
		gfx.drawText(song_test_last_note_detail, 4, 58)
	end

	if song_test_time % 15 == 0 then
		if song_test_mode == 1 then
			-- Play note.
			song_test_last_note = "Group = " .. note_group_index .. ", note = " .. last_note_index
			song_test_last_note_detail = "Chord = "
			for n = 1, #NOTE_GROUPS[note_group_index] do
				local note <const> = NOTE_GROUPS[note_group_index][n]
				if n > 1 then
					song_test_last_note_detail = song_test_last_note_detail .. ", "
				end
				if n == last_note_index then
					song_test_last_note_detail = song_test_last_note_detail .. "*" .. note .. "*"
				else
					song_test_last_note_detail = song_test_last_note_detail .. note
				end
			end
			celesta[last_note_index]:play(1, RATE_MULTIPLIER[NOTE_GROUPS[note_group_index][last_note_index] + 1])

		elseif last_note_index == 1 then
			-- Play chord.
			song_test_last_note = "Group = " .. note_group_index
			song_test_last_note_detail = "Chord = "
			for n = 1, #NOTE_GROUPS[note_group_index] do
				local note <const> = NOTE_GROUPS[note_group_index][n]
				celesta[n]:play(1, RATE_MULTIPLIER[note + 1])
				if n > 1 then
					song_test_last_note_detail = song_test_last_note_detail .. ", "
				end
				song_test_last_note_detail = song_test_last_note_detail .. note
			end
		end

		-- Advance indices.
		last_note_index += 1
		if last_note_index > #NOTE_GROUPS[note_group_index] then
			last_note_index = 1
			note_group_index = (note_group_index % #NOTE_GROUPS) + 1
		end
	end

	-- Handle button press.
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		-- Move to previous group.
		note_group_index = ((note_group_index - 2 + #NOTE_GROUPS) % #NOTE_GROUPS) + 1
		last_note_index = 1

	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		-- Move to next group.
		note_group_index = (note_group_index % #NOTE_GROUPS) + 1
		last_note_index = 1

	elseif playdate.buttonJustPressed(playdate.kButtonA) or
	       playdate.buttonJustPressed(playdate.kButtonB) then
		-- End song test.
		reset(true)
	end
	song_test_time += 1
end

-- Start game loop with zero sprites surrounding starting position.
local function init_sprite_test()
	local half_y <const> = TARGET_Y_SPACING // 2
	local points <const> =
	{
		{ 3, -TARGET_X_SPACING * 3, TARGET_Y_SPACING      + half_y},
		{ 4, -TARGET_X_SPACING * 3, 0                     + half_y},
		{ 5, -TARGET_X_SPACING * 3, -TARGET_Y_SPACING     + half_y},
		{ 6, -TARGET_X_SPACING * 3, -TARGET_Y_SPACING * 2 + half_y},

		{ 7, -TARGET_X_SPACING * 2, TARGET_Y_SPACING * 2},
		{ 8, -TARGET_X_SPACING * 2, TARGET_Y_SPACING},
		{ 9, -TARGET_X_SPACING * 2, 0},
		{10, -TARGET_X_SPACING * 2, -TARGET_Y_SPACING},
		{11, -TARGET_X_SPACING * 2, -TARGET_Y_SPACING * 2},

		{12, -TARGET_X_SPACING, TARGET_Y_SPACING      + half_y},
		{13, -TARGET_X_SPACING, 0                     + half_y},
		{14, -TARGET_X_SPACING, -TARGET_Y_SPACING     + half_y},
		{15, -TARGET_X_SPACING, -TARGET_Y_SPACING * 2 + half_y},

		{16, 0, TARGET_Y_SPACING * 2},
		{17, 0, TARGET_Y_SPACING},
		{18, 0, 0},
		{19, 0, -TARGET_Y_SPACING},
		{20, 0, -TARGET_Y_SPACING * 2},

		{21, TARGET_X_SPACING, TARGET_Y_SPACING      + half_y},
		{22, TARGET_X_SPACING, 0                     + half_y},
		{23, TARGET_X_SPACING, -TARGET_Y_SPACING     + half_y},
		{24, TARGET_X_SPACING, -TARGET_Y_SPACING * 2 + half_y},

		{25, TARGET_X_SPACING * 2, TARGET_Y_SPACING * 2},
		{26, TARGET_X_SPACING * 2, TARGET_Y_SPACING},
		{27, TARGET_X_SPACING * 2, 0},
		{28, TARGET_X_SPACING * 2, -TARGET_Y_SPACING},
		{29, TARGET_X_SPACING * 2, -TARGET_Y_SPACING * 2},

		{30, TARGET_X_SPACING * 3, TARGET_Y_SPACING      + half_y},
		{31, TARGET_X_SPACING * 3, 0                     + half_y},
		{32, TARGET_X_SPACING * 3, -TARGET_Y_SPACING     + half_y},
		{ 3, TARGET_X_SPACING * 3, -TARGET_Y_SPACING * 2 + half_y},
	}
	for i = 1, #points do
		local t = init_target(points[i][2], points[i][3])
		t.value = 0
		t.variation = points[i][1]
	end
end

-- When running on simulator in debug builds, export a few special
-- functions that are accessible through the debug console.
local function debug_export()
	if not playdate.isSimulator then
		return true
	end

	-- note_test: play notes in a loop.
	note_test = function()
		song_test_mode = 1
		song_test_time = 0
		note_group_index = 1
		last_note_index = 1
		set_global_volume(1)
		playdate.update = song_test
	end

	-- chord_test: play chords in a loop.
	chord_test = function()
		song_test_mode = 2
		song_test_time = 0
		note_group_index = 1
		set_global_volume(1)
		playdate.update = song_test
	end

	-- sprite_test: generate sprite variations.
	sprite_test = function()
		set_next_game_state(game_loop)
		reset(false)
		set_global_volume(1)
		init_sprite_test()

		-- Start at frame 1 instead of frame 0, so that the sprites are
		-- considered to be generated in the previous generation and won't
		-- be overwritten by the initial run of generate_solutions().
		global_frames = 1
	end

	return true
end
assert(debug_export())

--}}}

----------------------------------------------------------------------
--{{{ Game states and callbacks.

-- Title screen.
game_title = function()
	common_updates_for_game_title()

	if global_frames >= TITLE_ANIMATION_FRAMES then
		gfx.drawTextAligned("\u{2b05}/\u{27a1} *select*   \u{24b6} *start*", 200, TITLE_HELP_TEXT_POSITION, kTextAlignment.center)
	end

	global_frames += 1

	-- Left/Right: Select game mode.
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		if game_mode > 1 then
			game_mode -= 1
		end
		last_action_timestamp = global_frames
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		if game_mode < 8 then
			game_mode += 1
		end
		last_action_timestamp = global_frames
	end

	-- Up: Edit high score.
	if playdate.buttonJustPressed(playdate.kButtonUp) then
		last_action_timestamp = global_frames

		-- Only enter edit mode if there is a nonzero high score, otherwise
		-- we update last_action_timestamp while remaining in game_title state.
		-- This causes the bit width dialog to pop up.
		if persistent_state[SAVE_STATE_SCORES][game_mode] > 0 then
			set_next_game_state(game_edit_score)
			return
		end
	end

	-- Down: Update last_action_timestamp.  This causes draw_title_text
	-- to show bit width popup for current level.  This is mostly for
	-- consistency with handling of down button with game_edit_score.
	if playdate.buttonJustPressed(playdate.kButtonDown) then
		last_action_timestamp = global_frames
	end

	-- A/B: Start game.
	if playdate.buttonJustPressed(playdate.kButtonA) or
	   playdate.buttonJustPressed(playdate.kButtonB) then
		set_next_game_state(game_loop)
		reset(false)
		set_global_volume(1)
		assert(global_frames == 0)
		return
	end

	-- Enter attract mode after 10 seconds of idleness.
	if global_frames - last_action_timestamp >= 300 then
		set_next_game_state(game_demo)
		reset(false)
		set_global_volume(0)  -- Demo mode always runs in silence.
		assert(global_frames == 0)
		return
	end

	assert(debug_frame_rate())
	assert(debug_periodic_log())
end

-- Edit high scores.
game_edit_score = function()
	common_updates_for_game_title()

	if global_frames - last_action_timestamp < 4 then
		-- Draw animated rectangle.
		local scale <const> = (global_frames - last_action_timestamp + 1) / 5
		local width <const> = 240 * scale
		local height <const> = 38 * scale
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(200 - width / 2, 120 - height / 2, width, height)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRect(200 - width / 2, 120 - height / 2, width, height)

	else
		-- Draw static rectangle with text.
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(80, 101, 240, 38)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRect(80, 101, 240, 38)

		gfx.drawTextAligned("Reset score for level *" .. game_mode .. "*?", 200, 112, kTextAlignment.center)
		gfx.drawTextAligned("\u{24b7} *cancel*   \u{24b6} *confirm*", 200, TITLE_HELP_TEXT_POSITION, kTextAlignment.center)
	end

	global_frames += 1

	-- A: Return to title screen and reset score.
	--
	-- Note that "A" button press is ignored in the first few frames while
	-- we are still animating the dialog box.  This is to avoid accidentally
	-- erasing high scores through rapid button presses.
	if playdate.buttonJustPressed(playdate.kButtonA) and
	   global_frames - last_action_timestamp >= 4 then
		persistent_state[SAVE_STATE_SCORES][game_mode] = 0
		set_next_game_state(game_title)
		last_action_timestamp = global_frames
		return
	end

	-- B/Down: Return to title without resetting score.
	if playdate.buttonJustPressed(playdate.kButtonB) or
	   playdate.buttonJustPressed(playdate.kButtonDown) then
		set_next_game_state(game_title)
		last_action_timestamp = global_frames
		return
	end

	-- Left: Return to title without resetting score, also change game mode.
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		set_next_game_state(game_title)
		last_action_timestamp = global_frames
		if game_mode > 1 then
			game_mode -= 1
		end
		return
	end

	-- Right: Return to title without resetting score, also change game mode.
	if playdate.buttonJustPressed(playdate.kButtonRight) then
		set_next_game_state(game_title)
		last_action_timestamp = global_frames
		if game_mode < 8 then
			game_mode += 1
		end
		return
	end

	assert(debug_frame_rate())
	assert(debug_periodic_log())
end

-- Main game loop.
game_loop = function()
	common_updates_for_game_loop()

	-- Update clocks.
	update_game_time()

	-- Check for endgame.
	if thinking_time >= ENDGAME_HARD_LIMIT then
		-- Update high score.
		assert(persistent_state[SAVE_STATE_SCORES])
		assert(game_mode >= 1)
		assert(game_mode <= #persistent_state[SAVE_STATE_SCORES])
		if score > persistent_state[SAVE_STATE_SCORES][game_mode] then
			persistent_state[SAVE_STATE_SCORES][game_mode] = score
			set_next_game_state(game_over_high_score)
		else
			set_next_game_state(game_over)
		end
		global_frames = 0
		return
	end

	-- Handle player input.  This is done at the end of the update cycle
	-- since player input will modify state, which may cause some of the
	-- earlier draw functions to access outdated data.
	handle_input()

	assert(debug_frame_rate())
	assert(debug_periodic_log())
end

-- Attract mode.
game_demo = function()
	common_updates_for_game_loop()

	-- Update clocks.  For attract mode, thinking_time is always proportional
	-- to elapsed time, such that attract mode returns to title screen in
	-- fixed amount of time.
	global_frames += 1
	thinking_time = ENDGAME_HARD_LIMIT * global_frames / 900

	-- If sufficient time has passed, or any button has been pressed, we
	-- will return to title screen.
	if thinking_time >= ENDGAME_HARD_LIMIT or
	   playdate.buttonJustPressed(playdate.kButtonA) or
	   playdate.buttonJustPressed(playdate.kButtonB) or
	   playdate.buttonJustPressed(playdate.kButtonUp) or
	   playdate.buttonJustPressed(playdate.kButtonDown) or
	   playdate.buttonJustPressed(playdate.kButtonLeft) or
	   playdate.buttonJustPressed(playdate.kButtonRight) then
		reset(true)
		return
	end

	-- Generate demo input.
	demo_input()

	assert(debug_frame_rate())
	assert(debug_periodic_log())
end

-- Endgame.
game_over = function()
	common_updates_for_game_over(false)
end

-- Same as game_mode, but with an extra line to show high score change.
game_over_high_score = function()
	common_updates_for_game_over(true)
end

-- Playdate callbacks.
function playdate.update()
	-- Initialize state on first update.
	load_state()
	reset(true)

	-- Skip fade in animation for the first transition to game_title state,
	-- since title is already fully visible due to launcher image.
	global_frames = TITLE_FADE_IN_FRAMES

	-- Well, in theory the title is covered by launcher image, but in
	-- practice if we don't draw anything, we will get one blank frame on
	-- first update, so we will redraw the launch image here.
	gfx.image.new("launcher/launchImage"):draw(0, 0)

	-- Initialize menu options.  We need to do this after having loaded
	-- persistent_state, otherwise the defaults will be wrong.
	playdate.getSystemMenu():addMenuItem("reset", function() reset(true) end)
	playdate.getSystemMenu():addOptionsMenuItem(
		"hints", HINT_LABELS, HINT_LABELS[hint_mode],
		function(selected)
			if selected == "delayed" then
				hint_mode = HINTS_DELAYED
			elseif selected == "visible" then
				hint_mode = HINTS_VISIBLE
			else
				hint_mode = HINTS_HIDDEN
			end
		end)

	-- Initialize starfield on first update.
	init_starfield()

	assert(playdate.update == game_title)
	assert(debug_log("Game initialized"))
end

-- Update help text in menu screen.
function playdate.gameWillPause()
	assert(debug_save_state())

	local menu_image = gfx.image.new(400, 240, gfx.kColorWhite)
	gfx.pushContext(menu_image)
		if playdate.update == game_loop then
			-- Draw help text showing game controls in game_loop state.
			--
			-- Here we are making use of special characters available in
			-- Playdate's system font to save a bit of horizontal space:
			-- U+2B05 = Leftwards black arrow.
			-- U+27A1 = Black rightwards arrow.
			-- U+2B06 = Upwards black arrow.
			-- U+2B07 = Downwards black arrow.
			-- U+24B6 = Circled Latin capital letter A.
			-- U+24B7 = Circled Latin capital letter B.
			--
			-- As an aside, the fact that the rightwards arrow is in a different
			-- range is a quirk from Unicode:
			-- 2B00-2BFF = Miscellaneous symbols and arrows.
			-- 2700-27BF = Dingbats.
			-- 2460-24FF = Enclosed alphanumerics.
			--
			-- I don't understand why Unicode is so stingy about not allocating
			-- a consecutive range for all black arrows, considering that they
			-- also have a duplicate U+2B95 "rightwards black arrow" in the same
			-- range.
			--
			-- Anyways, Panic only made a right arrow symbol for U+27A1.  U+2B95
			-- and other arrows such as U+2B62 will not work.
			gfx.drawText("*Crank*: select", 4, 4)
			gfx.drawText("(docked) \u{2b05}/\u{27a1}: select", 4, 26)
			gfx.drawText("\u{24b6}/\u{2b06}: move forward", 4, 48)
			gfx.drawText("\u{24b7}/\u{2b07}: undo", 4, 70)

			gfx.drawText("Make constellations", 4, 110)
			gfx.drawText("where bitwise-xor of all", 4, 132)
			if all_ones == 0xf then
				gfx.drawText("values equals *0* or *F*.", 4, 154)
			else
				assert(all_ones == 0xff)
				gfx.drawText("values equals *00* or *FF*.", 4, 154)
			end

		elseif playdate.update == game_title then
			-- Show title screen controls.
			gfx.drawText("\u{24b6}/\u{24b7}: start", 4, 4)
			gfx.drawText("\u{2b05}/\u{27a1}: select level", 4, 26)
			if persistent_state[SAVE_STATE_SCORES][game_mode] > 0 then
				gfx.drawText("\u{2b06} + \u{24b6}: reset score", 4, 48)
			end

		elseif playdate.update == game_edit_score then
			-- Show edit score controls.
			gfx.drawText("\u{24b6}: reset score", 4, 4)
			gfx.drawText("\u{24b7}: cancel", 4, 26)
			gfx.drawText("\u{2b05}/\u{27a1}: select level", 4, 48)

		else
			-- Show attract mode and game over screen controls.
			gfx.drawText("\u{24b6}/\u{24b7}: return to title", 4, 4)
		end

		-- Always include version info.
		gfx.drawText("Xor Constellation v" .. playdate.metadata.version, 4, 198)
		gfx.drawText("omoikane@uguu.org", 4, 220)
	gfx.popContext(menu_image)
	playdate.setMenuImage(menu_image)
end

playdate.gameWillTerminate = save_state
playdate.deviceWillSleep = save_state

--}}}
