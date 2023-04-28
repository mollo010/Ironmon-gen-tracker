Program = {
	currentScreen = 1,
	previousScreens = {}, -- breadcrumbs for clicking the Back button
	inStartMenu = false,
	inCatchingTutorial = false,
	hasCompletedTutorial = false,
	activeFormId = 0,
	Frames = {
		waitToDraw = 30, -- counts down
		highAccuracyUpdate = 10, -- counts down
		lowAccuracyUpdate = 30, -- counts down
		three_sec_update = 180, -- counts down
		saveData = 3600, -- counts down
		carouselActive = 0, -- counts up
		battleDataDelay = 60, -- counts down
	},
}

Program.GameData = {
	mapId = 0, -- was previously Battle.CurrentRoute.mapId
	wildBattles = -999, -- used to track differences in GAME STATS
	trainerBattles = -999, -- used to track differences in GAME STATS
	friendshipRequired = 220,
	evolutionStones = { -- The evolution stones currently in bag
			[93] = 0, -- Sun Stone
			[94] = 0, -- Moon Stone
			[95] = 0, -- Fire Stone
			[96] = 0, -- Thunder Stone
			[97] = 0, -- Water Stone
			[98] = 0, -- Leaf Stone
	},
}

Program.ActiveRepel = {
	inUse = false,
	stepCount = 0,
	duration = 100,
	shouldDisplay = function(self)
		local enabledAndAllowed = Options["Display repel usage"] and Program.ActiveRepel.inUse and Program.isValidMapLocation()
		local hasConflict = Battle.inBattle or Battle.battleStarting or Program.inStartMenu or GameOverScreen.isDisplayed or LogOverlay.isDisplayed
		local inHallOfFame = Program.GameData.mapId ~= nil and RouteData.Locations.IsInHallOfFame[Program.GameData.mapId]
		return enabledAndAllowed and not hasConflict and not inHallOfFame
	end,
}

Program.Pedometer = {
	totalSteps = 0, -- updated from GAME_STATS
	lastResetCount = 0, -- num steps since last "reset", for counting new steps
	goalSteps = 0, -- num steps that is set by the user as a milestone goal to reach, 0 to disable
	getCurrentStepcount = function(self) return math.max(self.totalSteps - self.lastResetCount, 0) end,
	isInUse = function(self)
		local enabledAndAllowed = Options["Display pedometer"] and Program.isValidMapLocation()
		local hasConflict = Battle.inBattle or Battle.battleStarting or GameOverScreen.isDisplayed or LogOverlay.isDisplayed
		return enabledAndAllowed and not hasConflict
	end,
}

Program.AutoSaver = {
	knownSaveCount = 0,
	framesUntilNextSave = -1,
	updateSaveCount = function(self) -- returns true if the savecount has been updated
		return false
	end,
	checkForNextSave = function(self)
		if not Main.IsOnBizhawk() then return end -- flush saveRAM only for Bizhawk
		if self:updateSaveCount() then
			client.saveram()
		end
	end
}

function Program.initialize()
	-- If an update is available, offer that up first before going to the Tracker StartupScreen
	if Main.Version.showUpdate then
		Program.currentScreen = UpdateScreen
	else
		Program.currentScreen = StartupScreen
	end

	-- Check if requirement for Friendship evos has changed (Default:219, MakeEvolutionsFaster:159)
	--local friendshipRequired = Memory.readbyte(GameSettings.FriendshipRequiredToEvo) + 1
	--if friendshipRequired > 1 and friendshipRequired <= 220 then
	--	Program.GameData.friendshipRequired = friendshipRequired
	--end

	Program.updateBattleEncounterType()
	Program.AutoSaver:updateSaveCount()

	-- Update data asap
	Program.Frames.highAccuracyUpdate = 0
	Program.Frames.lowAccuracyUpdate = 0
	Program.Frames.three_sec_update = 0
	Program.Frames.waitToDraw = 1
end

function Program.mainLoop()
	if Main.loadNextSeed and not Main.IsOnBizhawk() then -- required escape for mGBA
		Main.LoadNextRom()
		return
	end

	Input.checkForInput()

	Program.update()

	Battle.update()

	CustomCode.afterEachFrame()

	Program.redraw(false)

	Program.stepFrames() -- TODO: Really want a better way to handle this

end

function Program.mainLoopGen2()
	if Main.loadNextSeed and not Main.IsOnBizhawk() then -- required escape for mGBA
		Main.LoadNextRom()
		return
	end

	Input.checkForInput()

	Program.updateGen2()

	Battle.updateGen2()

	CustomCode.afterEachFrame()

	Program.redraw(false)

	Program.stepFrames() -- TODO: Really want a better way to handle this

end


-- 'forced' = true will force a draw, skipping the normal frame wait time
function Program.redraw(forced)
	-- Only redraw the screen every half second (60 frames/sec)
	if not forced and Program.Frames.waitToDraw > 0 then
		Program.Frames.waitToDraw = Program.Frames.waitToDraw - 1
		return
	end

	Program.Frames.waitToDraw = 30

	if Main.IsOnBizhawk() then
		-- Draw the repel icon here so that it's drawn regardless of what tracker screen is displayed
		if Program.ActiveRepel:shouldDisplay() then
			--Drawing.drawRepelUsage()
		end

		-- The LogOverlay viewer doesn't occupy the same screen space and needs its own check
		if LogOverlay.isDisplayed then
			LogOverlay.drawScreen()
		end

		if Program.currentScreen ~= nil and type(Program.currentScreen.drawScreen) == "function" then

			Program.currentScreen.drawScreen()
		end

		if TeamViewArea.isDisplayed() then
			TeamViewArea.drawScreen()
		end
	else
		MGBA.ScreenUtils.updateTextBuffers()
	end

	CustomCode.afterRedraw()
end

function Program.changeScreenView(screen)
	-- table.insert(Program.previousScreens, Program.currentScreen) -- TODO: implement later
	Program.currentScreen = screen
	Program.redraw(true)
end

-- TODO: Currently unused, implement later
function Program.goBackToPreviousScreen()
	Utils.printDebug("DEBUG: From %s previous screens.", #Program.previousScreens)
	if #Program.previousScreens == 0 then
		Program.currentScreen = TrackerScreen
	else
		Program.currentScreen = table.remove(Program.previousScreens)
	end
	Program.redraw(true)
end

function Program.destroyActiveForm()
	if Program.activeFormId ~= nil and Program.activeFormId ~= 0 then
		forms.destroy(Program.activeFormId)
		Program.activeFormId = 0
	end
end

function Program.update()
	-- Be careful adding too many things to this 10 frame update
	if Program.Frames.highAccuracyUpdate == 0 then

		Program.updateMapLocation() -- trying this here to solve many future problems

		-- If the lead Pokemon changes, then update the animated Pokemon picture box
		if Options["Animated Pokemon popout"] then

			local leadPokemon = Tracker.getPokemon(Battle.Combatants.LeftOwn, true)

			if leadPokemon ~= nil and leadPokemon.pokemonID ~= 0 and Program.isValidMapLocation() then
				if leadPokemon.pokemonID ~= Drawing.AnimatedPokemon.pokemonID then
					Drawing.AnimatedPokemon:setPokemon(leadPokemon.pokemonID)
				elseif Drawing.AnimatedPokemon.requiresRelocating then
					Drawing.AnimatedPokemon:relocatePokemon()
				end
			end
		end
	end

	-- Don't bother reading game data before a game even begins
	if not Program.isValidMapLocation() then


		return
	end



	-- Get any "new" information from game memory for player's pokemon team every half second (60 frames/sec)
	if Program.Frames.lowAccuracyUpdate == 0 then

		--Program.inCatchingTutorial = Program.isInCatchingTutorial()

		if true  then

			Program.updatePokemonTeams()

			TeamViewArea.buildOutPartyScreen()

			if Program.isValidMapLocation() then

				if Program.currentScreen == StartupScreen then
					-- If the game hasn't started yet, show the start-up screen instead of the main Tracker screen
					Program.currentScreen = TrackerScreen
				elseif RouteData.Locations.IsInHallOfFame[Program.GameData.mapId] and not GameOverScreen.enteredFromSpecialLocation then
					GameOverScreen.enteredFromSpecialLocation = true
					Program.currentScreen = GameOverScreen
				end

			elseif GameOverScreen.enteredFromSpecialLocation then
				GameOverScreen.enteredFromSpecialLocation = false
			end

			-- Check if summary screen has being shown
			if not Tracker.Data.hasCheckedSummary then
				if Memory.readbyte(GameSettings.sMonSummaryScreen) ~= 0 then
					Tracker.Data.hasCheckedSummary = true
				end
			end

			if not Battle.inBattle then
				Program.updateBattleEncounterType()
			end

			-- Check if a Pokemon in the player's party is learning a move, if so track it
			--local learnedInfoTable = Program.getLearnedMoveInfoTable()
			--if learnedInfoTable.pokemonID ~= nil then
			---	Tracker.TrackMove(learnedInfoTable.pokemonID, learnedInfoTable.moveId, learnedInfoTable.level)
			--end

			if false and Options["Display repel usage"] and not (Battle.inBattle or Battle.battleStarting) then
				-- Check if the player is in the start menu (for hiding the repel usage icon)
				Program.inStartMenu = Program.isInStartMenu()
				-- Check for active repel and steps remaining
				if not Program.inStartMenu then
					Program.updateRepelSteps()
				end
			end

			-- Update step count only if the option is enabled
			if Program.Pedometer:isInUse() then
				Program.Pedometer.totalSteps = 0
			end

			Program.AutoSaver:checkForNextSave()
			TimeMachineScreen.checkCreatingRestorePoint()
		end
	end

	-- Only update "Heals in Bag", Evolution Stones, "PC Heals", and "Badge Data" info every 3 seconds (3 seconds * 60 frames/sec)
	if Program.Frames.three_sec_update == 0 then
		Program.updateBagItems()

		Program.updatePCHeals()

		Program.updateBadgesObtained()

	end

	-- Only save tracker data every 1 minute (60 seconds * 60 frames/sec) and after every battle (set elsewhere)
	if Program.Frames.saveData == 0 then
		-- Don't bother saving tracked data if the player doesn't have a Pokemon yet
		if Options["Auto save tracked game data"] and Tracker.getPokemon(1, true) ~= nil then
			Tracker.saveData()
		end
	end

	if Program.Frames.lowAccuracyUpdate == 0 then
		CustomCode.afterProgramDataUpdate()
	end

end








function Program.updateGen2()
	-- Be careful adding too many things to this 10 frame update
	if Program.Frames.highAccuracyUpdate == 0 then

		Program.updateMapLocation() -- trying this here to solve many future problems

		-- If the lead Pokemon changes, then update the animated Pokemon picture box
		if Options["Animated Pokemon popout"] then

			local leadPokemon = Tracker.getPokemon(Battle.Combatants.LeftOwn, true)

			if leadPokemon ~= nil and leadPokemon.pokemonID ~= 0 and Program.isValidMapLocation() then
				if leadPokemon.pokemonID ~= Drawing.AnimatedPokemon.pokemonID then
					Drawing.AnimatedPokemon:setPokemon(leadPokemon.pokemonID)
				elseif Drawing.AnimatedPokemon.requiresRelocating then
					Drawing.AnimatedPokemon:relocatePokemon()
				end
			end
		end
	end

	-- Don't bother reading game data before a game even begins
	if not Program.isValidMapLocation() then


		return
	end



	-- Get any "new" information from game memory for player's pokemon team every half second (60 frames/sec)
	if Program.Frames.lowAccuracyUpdate == 0 then

		--Program.inCatchingTutorial = Program.isInCatchingTutorial()

		if true  then

			Program.updatePokemonTeamsGen2()

			TeamViewArea.buildOutPartyScreen()

			if Program.isValidMapLocation() then

				if Program.currentScreen == StartupScreen then
					-- If the game hasn't started yet, show the start-up screen instead of the main Tracker screen
					Program.currentScreen = TrackerScreen
				elseif RouteData.Locations.IsInHallOfFame[Program.GameData.mapId] and not GameOverScreen.enteredFromSpecialLocation then
					GameOverScreen.enteredFromSpecialLocation = true
					Program.currentScreen = GameOverScreen
				end

			elseif GameOverScreen.enteredFromSpecialLocation then
				GameOverScreen.enteredFromSpecialLocation = false
			end

			-- Check if summary screen has being shown
			if not Tracker.Data.hasCheckedSummary then
				if Memory.readbyte(GameSettings.sMonSummaryScreen) ~= 0 then
					Tracker.Data.hasCheckedSummary = true
				end
			end

			if not Battle.inBattle then
				Program.updateBattleEncounterType()
			end

			-- Check if a Pokemon in the player's party is learning a move, if so track it
			--local learnedInfoTable = Program.getLearnedMoveInfoTable()
			--if learnedInfoTable.pokemonID ~= nil then
			---	Tracker.TrackMove(learnedInfoTable.pokemonID, learnedInfoTable.moveId, learnedInfoTable.level)
			--end

			if false and Options["Display repel usage"] and not (Battle.inBattle or Battle.battleStarting) then
				-- Check if the player is in the start menu (for hiding the repel usage icon)
				Program.inStartMenu = Program.isInStartMenu()
				-- Check for active repel and steps remaining
				if not Program.inStartMenu then
					Program.updateRepelSteps()
				end
			end

			-- Update step count only if the option is enabled
			if Program.Pedometer:isInUse() then
				Program.Pedometer.totalSteps = 0
			end

			Program.AutoSaver:checkForNextSave()
			TimeMachineScreen.checkCreatingRestorePoint()
		end
	end

	-- Only update "Heals in Bag", Evolution Stones, "PC Heals", and "Badge Data" info every 3 seconds (3 seconds * 60 frames/sec)
	if Program.Frames.three_sec_update == 0 then
		Program.updateBagItemsGen2()

		Program.updatePCHeals()

		Program.updateBadgesObtained()

	end

	-- Only save tracker data every 1 minute (60 seconds * 60 frames/sec) and after every battle (set elsewhere)
	if Program.Frames.saveData == 0 then
		-- Don't bother saving tracked data if the player doesn't have a Pokemon yet
		if Options["Auto save tracked game data"] and Tracker.getPokemon(1, true) ~= nil then
			Tracker.saveData()
		end
	end

	if Program.Frames.lowAccuracyUpdate == 0 then
		CustomCode.afterProgramDataUpdate()
	end

end








function Program.stepFrames()
	Program.Frames.highAccuracyUpdate = (Program.Frames.highAccuracyUpdate - 1) % 10
	Program.Frames.lowAccuracyUpdate = (Program.Frames.lowAccuracyUpdate - 1) % 30
	Program.Frames.three_sec_update = (Program.Frames.three_sec_update - 1) % 180
	Program.Frames.saveData = (Program.Frames.saveData - 1) % 3600
	Program.Frames.carouselActive = Program.Frames.carouselActive + 1
end

function Program.updateRepelSteps()
	-- Checks for an active repel and updates the current steps remaining
	-- Game uses a variable for the repel steps remaining, which remains at 0 when there's no active repel
	local saveblock1Addr = Utils.getSaveBlock1Addr()
	local repelStepCountOffset = Utils.inlineIf(GameSettings.game == 3, 0x40, 0x42)
	local repelStepCount = Memory.readbyte(saveblock1Addr + GameSettings.gameVarsOffset + repelStepCountOffset)
	if repelStepCount ~= nil and repelStepCount > 0 then
		Program.ActiveRepel.inUse = true
		if repelStepCount ~= Program.ActiveRepel.stepCount then
			Program.ActiveRepel.stepCount = repelStepCount
			-- Duration is defaulted to normal repel (100 steps), check if super or max is used instead
			if repelStepCount > Program.ActiveRepel.duration then
				if repelStepCount <= 200 then
					-- Super Repel
					Program.ActiveRepel.duration = 200
				elseif repelStepCount <= 250 then
					-- Max Repel
					Program.ActiveRepel.duration = 250
				end
			end
		end
	elseif repelStepCount == 0 then
		-- Reset the active repel data when none is active (remaining step count 0)
		Program.ActiveRepel.inUse = false
		Program.ActiveRepel.stepCount = 0
		Program.ActiveRepel.duration = 100
	end
end

function Program.updatePokemonTeams()


	-- Check for updates to each pokemon team
	local addressOffset = 0

	-- Check if it's a new game (no Pokémon yet)
	if not Tracker.Data.isNewGame and Tracker.Data.ownTeam[1] == 0 then
		Tracker.Data.isNewGame = true
	end

	for i = 1, 6, 1 do
		-- Lookup information on the player's Pokemon first
		local id = Memory.readbyte(GameSettings.pstats + addressOffset)

		-- local previousPersonality = Tracker.Data.ownTeam[i] -- See below
		Tracker.Data.ownTeam[i] = id

		if id ~= 0 then
			local newPokemonData = Program.readNewPokemon(GameSettings.pstats + addressOffset, id)

			if Program.validPokemonData(newPokemonData) then

				-- Sets the player's trainerID as soon as they get their first Pokemon
				if Tracker.Data.isNewGame and newPokemonData.trainerID ~= nil and newPokemonData.trainerID ~= 0 then
					if Tracker.Data.trainerID == nil or Tracker.Data.trainerID == 0 then
						Tracker.Data.trainerID = newPokemonData.trainerID
					elseif Tracker.Data.trainerID ~= newPokemonData.trainerID then
						-- Reset the tracker data as old data was loaded and we have a different trainerID now
						print("Old/Incorrect data was detected for this ROM. Initializing new data.")
						Tracker.resetData()
						Tracker.Data.trainerID = newPokemonData.trainerID
					end

					-- Unset the new game flag
					Tracker.Data.isNewGame = false
				end

				-- Remove trainerID value from the pokemon data itself since it's now owned by the player, saves data space
				-- No longer remove, as it's currently used to verify Trainer pokemon with personality values of 0
				newPokemonData.trainerID = nil

				-- Include experience information for each Pokemon in the player's team
				--local curExp, totalExp = Program.getNextLevelExp(newPokemonData.pokemonID, newPokemonData.level, newPokemonData.experience)
				newPokemonData.currentExp = 0
				newPokemonData.totalExp = 0

				Tracker.addUpdatePokemon(newPokemonData, id, true)

				-- TODO: Removing for now until some better option is available, not sure there is one
				-- If this is a newly caught Pokémon, track all of its moves. Can't do this later cause TMs/HMs
				-- if previousPersonality == 0 then
				-- 	for _, move in ipairs(newPokemonData.moves) do
				-- 		Tracker.TrackMove(newPokemonData.pokemonID, move.id, newPokemonData.level)
				-- 	end
				-- end
			end

		end

		-- Then lookup information on the opposing Pokemon


		-- Next Pokemon - Each is offset by 44 bytes
		addressOffset = addressOffset + 44
	end


	local trainerID = Memory.readbyte(GameSettings.estats  )
	Tracker.Data.otherTeam[1] = trainerID

	if  trainerID ~= 0 then
		local newPokemonData = Program.readNewEnemyPokemon(GameSettings.estats , trainerID)

		if Program.validPokemonData(newPokemonData) then

			-- Double-check a race condition where current PP values are wildly out of range if retrieved right before a battle begins
			if not Battle.inBattle then
				for _, move in pairs(newPokemonData.moves) do
					if move.id ~= 0 then
						move.pp = tonumber(MoveData.Moves[move.id].pp) -- set value to max PP
					end
				end
			end

			Tracker.addUpdatePokemon(newPokemonData, trainerID, false)
		end
	end

end







function Program.updatePokemonTeamsGen2()
	-- Check for updates to each pokemon team
	local addressOffset = 0

	-- Check if it's a new game (no Pokémon yet)
	if not Tracker.Data.isNewGame and Tracker.Data.ownTeam[1] == 0 then
		Tracker.Data.isNewGame = true
	end

	for i = 1, 6, 1 do
		-- Lookup information on the player's Pokemon first
		local id = Memory.readbyte(GameSettings.pstats + addressOffset)

		-- local previousPersonality = Tracker.Data.ownTeam[i] -- See below
		Tracker.Data.ownTeam[i] = id

		if id ~= 0 then
			local newPokemonData = Program.readNewPokemonGen2(GameSettings.pstats + addressOffset, id)

			if Program.validPokemonData(newPokemonData) then

				-- Sets the player's trainerID as soon as they get their first Pokemon
				if Tracker.Data.isNewGame and newPokemonData.trainerID ~= nil and newPokemonData.trainerID ~= 0 then
					if Tracker.Data.trainerID == nil or Tracker.Data.trainerID == 0 then
						Tracker.Data.trainerID = newPokemonData.trainerID
					elseif Tracker.Data.trainerID ~= newPokemonData.trainerID then
						-- Reset the tracker data as old data was loaded and we have a different trainerID now
						print("Old/Incorrect data was detected for this ROM. Initializing new data.")
						Tracker.resetData()
						Tracker.Data.trainerID = newPokemonData.trainerID
					end

					-- Unset the new game flag
					Tracker.Data.isNewGame = false
				end

				-- Remove trainerID value from the pokemon data itself since it's now owned by the player, saves data space
				-- No longer remove, as it's currently used to verify Trainer pokemon with personality values of 0
				newPokemonData.trainerID = nil

				-- Include experience information for each Pokemon in the player's team
				--local curExp, totalExp = Program.getNextLevelExp(newPokemonData.pokemonID, newPokemonData.level, newPokemonData.experience)
				newPokemonData.currentExp = 0
				newPokemonData.totalExp = 0

				Tracker.addUpdatePokemon(newPokemonData, id, true)

				-- TODO: Removing for now until some better option is available, not sure there is one
				-- If this is a newly caught Pokémon, track all of its moves. Can't do this later cause TMs/HMs
				-- if previousPersonality == 0 then
				-- 	for _, move in ipairs(newPokemonData.moves) do
				-- 		Tracker.TrackMove(newPokemonData.pokemonID, move.id, newPokemonData.level)
				-- 	end
				-- end
			end

		end

		-- Then lookup information on the opposing Pokemon


		-- Next Pokemon - Each is offset by 44 bytes
		addressOffset = addressOffset + 44
	end


	local trainerID = Memory.readbyte(GameSettings.estats  )
	Tracker.Data.otherTeam[1] = trainerID

	if  trainerID ~= 0 then
		local newPokemonData = Program.readNewEnemyPokemonGen2(GameSettings.estats , trainerID)

		if Program.validPokemonData(newPokemonData) then

			-- Double-check a race condition where current PP values are wildly out of range if retrieved right before a battle begins
			if not Battle.inBattle then
				for _, move in pairs(newPokemonData.moves) do
					if move.id ~= 0 then
						move.pp = tonumber(MoveData.Moves[move.id].pp) -- set value to max PP
					end
				end
			end

			Tracker.addUpdatePokemon(newPokemonData, trainerID, false)
		end
	end

end


function Program.readNewPokemonGen2(startAddress, id)
	-- Pokemon Data structure:https://datacrystal.romhacking.net/wiki/Pokémon_Red/Blue:RAM_map#Player


	local species = id -- Pokemon's Pokedex ID
	local abilityNum = "None" -- [0 or 1] to determine which ability, available in PokemonData

	-- Determine status condition
	local status_aux = Memory.readbyte(startAddress + 16)
	local sleep_turns_result = 0
	local status_result = 0
	if status_aux == 0 then --None
		status_result = 0
	elseif status_aux < 8 then -- Sleep
		sleep_turns_result = status_aux
		status_result = 1
	elseif status_aux == 8 then -- Poison
		status_result = 2
	elseif status_aux == 16 then -- Burn
		status_result = 3
	elseif status_aux == 32 then -- Freeze
		status_result = 4
	elseif status_aux == 64 then -- Paralyze
		status_result = 5

	end

	-- Can likely improve this further using memory.read_bytes_as_array but would require testing to verify
	local cur_level =  Memory.readbyte(startAddress + 31)
	local curr_hp= Utils.reverseEndian16(Memory.readword(startAddress+34))
	local maxhp =  Utils.reverseEndian16( Memory.readword(startAddress + 36))
	local attack1 =  Utils.reverseEndian16( Memory.readword(startAddress + 38))
	local def =  Utils.reverseEndian16(Memory.readword(startAddress + 40))
	local sped=  Utils.reverseEndian16(Memory.readword(startAddress + 42))
	local spatk = Utils.reverseEndian16(Memory.readword(startAddress + 44))
	local spad = Utils.reverseEndian16(Memory.readword(startAddress + 46))

	local attack= Memory.readdword(startAddress+2)
	local move_pp= Memory.readdword(startAddress+23)
	local train_id =id


	local item =Memory.readbyte(startAddress+1)


	return {
		personality = (id),
		nickname = MiscData.InternalID[id],
		trainerID = train_id,
		pokemonID = species,
		heldItem = item,
		experience = 0,
		friendship = 0,
		level = cur_level,
		nature = 0,
		isEgg = 0, -- [0 or 1] to determine if mon is still an egg (1 if true)
		abilityNum = abilityNum,
		status = status_result,
		sleep_turns = sleep_turns_result,
		curHP = math.floor(curr_hp),
		stats = {
			hp = math.floor(maxhp),
			atk = math.floor(attack1),
			def = math.floor(def),
			spa = math.floor(spatk),
			spd=math.floor(spad),
			spe = math.floor(sped),
		},
		statStages = { hp = 7, atk = 7, def = 7, spa = 7,spd=7,  spe = 7, acc = 7, eva = 7 },
		moves = {
			{ id = Utils.getbits(attack, 0, 8), level = 1, pp = Utils.getbits(move_pp, 0, 6)   },
			{ id = Utils.getbits(attack, 8, 8), level = 1, pp = Utils.getbits(move_pp, 8, 6) },
			{ id = Utils.getbits(attack, 16, 8), level = 1, pp = Utils.getbits(move_pp, 16, 6) },
			{ id = Utils.getbits(attack, 24, 8), level = 1, pp = Utils.getbits(move_pp, 24, 6) },
		},

		-- Unused data that can be added back in later
		-- secretID = Utils.getbits(otid, 16, 16), -- Unused
		-- pokerus = Utils.getbits(misc1, 0, 8), -- Unused
		-- iv = misc2,
		-- ev1 = effort1,
		-- ev2 = effort2,
	}
end


function Program.readNewEnemyPokemonGen2(startAddress, id)
	-- Pokemon Data structure:https://datacrystal.romhacking.net/wiki/Pokémon_Red/Blue:RAM_map#Player



	local species = id -- Pokemon's Pokedex ID
	local abilityNum = "None" -- [0 or 1] to determine which ability, available in PokemonData

	-- Determine status condition
	local status_aux = Memory.readbyte(startAddress + 14)
	local sleep_turns_result = 0
	local status_result = 0
	if status_aux == 0 then --None
		status_result = 0
	elseif status_aux < 8 then -- Sleep
		sleep_turns_result = status_aux
		status_result = 1
	elseif status_aux == 8 then -- Poison
		status_result = 2
	elseif status_aux == 16 then -- Burn
		status_result = 3
	elseif status_aux == 32 then -- Freeze
		status_result = 4
	elseif status_aux == 64 then -- Paralyze
		status_result = 5

	end

	-- Can likely improve this further using memory.read_bytes_as_array but would require testing to verify
	local cur_level = Memory.readbyte(startAddress + 13)
	local curr_hp= Utils.reverseEndian16(Memory.readword(startAddress+16))
	local maxhp =  Utils.reverseEndian16( Memory.readword(startAddress + 15))
	local attack1 =  Utils.reverseEndian16( Memory.readword(startAddress + 17))
	local def =  Utils.reverseEndian16(Memory.readword(startAddress + 19))
	local sped=  Utils.reverseEndian16(Memory.readword(startAddress + 21))
	local spatk = Utils.reverseEndian16(Memory.readword(startAddress + 23))
	local spad = Utils.reverseEndian16(Memory.readword(startAddress + 48))



	local attack= Memory.readdword(startAddress+2)
	local move_pp= Memory.readdword(startAddress+8)
	local train_id =Memory.readword(startAddress+12)


	return {
		personality = id,
		nickname = MiscData.InternalID[id],
		trainerID = "enemy",
		pokemonID = species,
		heldItem = nil,
		experience = 0,
		friendship = 0,
		level = cur_level,
		nature = 0,
		isEgg = 0, -- [0 or 1] to determine if mon is still an egg (1 if true)
		abilityNum = abilityNum,
		status = status_result,
		sleep_turns = sleep_turns_result,
		curHP = math.floor(curr_hp),
		stats = {
			hp = math.floor(maxhp),
			atk = math.floor(attack1),
			def = math.floor(def),
			spa = math.floor(spatk),
			spd = math.floor(spad),
			spe = math.floor(sped),
		},
		statStages = { hp = 7, atk = 7, def = 7, spa = 7, spd = 7, spe = 7, acc = 7, eva = 7 },
		moves = {
			{ id = Utils.getbits(attack, 0, 8), level = 1, pp = Utils.getbits(move_pp, 0, 8) },
			{ id = Utils.getbits(attack, 8, 8), level = 1, pp = Utils.getbits(move_pp, 8, 8) },
			{ id = Utils.getbits(attack, 16, 8), level = 1, pp = Utils.getbits(move_pp, 16, 8) },
			{ id = Utils.getbits(attack, 24, 8), level = 1, pp = Utils.getbits(move_pp, 24, 8) },
		},

		-- Unused data that can be added back in later
		-- secretID = Utils.getbits(otid, 16, 16), -- Unused
		-- pokerus = Utils.getbits(misc1, 0, 8), -- Unused
		-- iv = misc2,
		-- ev1 = effort1,
		-- ev2 = effort2,
	}
end



function Program.readNewPokemon(startAddress, id)
	-- Pokemon Data structure:https://datacrystal.romhacking.net/wiki/Pokémon_Red/Blue:RAM_map#Player



	local species = PokemonData.getIdFromName(MiscData.InternalID[id]) -- Pokemon's Pokedex ID
	local abilityNum = "None" -- [0 or 1] to determine which ability, available in PokemonData

	-- Determine status condition
	local status_aux = Memory.readbyte(startAddress + 4)
	local sleep_turns_result = 0
	local status_result = 0
	if status_aux == 0 then --None
		status_result = 0
	elseif status_aux < 8 then -- Sleep
		sleep_turns_result = status_aux
		status_result = 1
	elseif status_aux == 8 then -- Poison
		status_result = 2
	elseif status_aux == 16 then -- Burn
		status_result = 3
	elseif status_aux == 32 then -- Freeze
		status_result = 4
	elseif status_aux == 64 then -- Paralyze
		status_result = 5

	end

	-- Can likely improve this further using memory.read_bytes_as_array but would require testing to verify
	local cur_level = Memory.readbyte(startAddress + 33)
	local curr_hp= Utils.reverseEndian16(Memory.readword(startAddress+1))
	local maxhp =  Utils.reverseEndian16( Memory.readword(startAddress + 34))
	local attack1 =  Utils.reverseEndian16( Memory.readword(startAddress + 36))
	local def =  Utils.reverseEndian16(Memory.readword(startAddress + 38))
	local sped=  Utils.reverseEndian16(Memory.readword(startAddress + 40))
	local spatk = Utils.reverseEndian16(Memory.readword(startAddress + 42))
	local attack= Memory.readdword(startAddress+8)
	local move_pp= Memory.readdword(startAddress+29)
	local train_id =Memory.readword(startAddress+12)


	return {
		personality = id,
		nickname = MiscData.InternalID[id],
		trainerID = train_id,
		pokemonID = species,
		heldItem = nil,
		experience = 0,
		friendship = 0,
		level = cur_level,
		nature = 0,
		isEgg = 0, -- [0 or 1] to determine if mon is still an egg (1 if true)
		abilityNum = abilityNum,
		status = status_result,
		sleep_turns = sleep_turns_result,
		curHP = curr_hp,
		stats = {
			hp = maxhp,
			atk = attack1,
			def = def,
			spa = spatk,

			spe = sped,
		},
		statStages = { hp = 6, atk = 6, def = 6, spa = 6,  spe = 6, acc = 6, eva = 6 },
		moves = {
			{ id = Utils.getbits(attack, 0, 8), level = 1, pp = Utils.getbits(move_pp, 0, 6)   },
			{ id = Utils.getbits(attack, 8, 8), level = 1, pp = Utils.getbits(move_pp, 8, 6) },
			{ id = Utils.getbits(attack, 16, 8), level = 1, pp = Utils.getbits(move_pp, 16, 6) },
			{ id = Utils.getbits(attack, 24, 8), level = 1, pp = Utils.getbits(move_pp, 24, 6) },
		},

		-- Unused data that can be added back in later
		-- secretID = Utils.getbits(otid, 16, 16), -- Unused
		-- pokerus = Utils.getbits(misc1, 0, 8), -- Unused
		-- iv = misc2,
		-- ev1 = effort1,
		-- ev2 = effort2,
	}
end


function Program.readNewEnemyPokemon(startAddress, id)
	-- Pokemon Data structure:https://datacrystal.romhacking.net/wiki/Pokémon_Red/Blue:RAM_map#Player



	local species = PokemonData.getIdFromName(MiscData.InternalID[id]) -- Pokemon's Pokedex ID
	local abilityNum = "None" -- [0 or 1] to determine which ability, available in PokemonData

	-- Determine status condition
	local status_aux = Memory.readbyte(startAddress + 4)
	local sleep_turns_result = 0
	local status_result = 0
	if status_aux == 0 then --None
		status_result = 0
	elseif status_aux < 8 then -- Sleep
		sleep_turns_result = status_aux
		status_result = 1
	elseif status_aux == 8 then -- Poison
		status_result = 2
	elseif status_aux == 16 then -- Burn
		status_result = 3
	elseif status_aux == 32 then -- Freeze
		status_result = 4
	elseif status_aux == 64 then -- Paralyze
		status_result = 5

	end

	-- Can likely improve this further using memory.read_bytes_as_array but would require testing to verify
	local cur_level = Memory.readbyte(startAddress + 14)
	local curr_hp= Utils.reverseEndian16(Memory.readword(startAddress+1))
	local maxhp =  Utils.reverseEndian16( Memory.readword(startAddress + 15))
	local attack1 =  Utils.reverseEndian16( Memory.readword(startAddress + 17))
	local def =  Utils.reverseEndian16(Memory.readword(startAddress + 19))
	local sped=  Utils.reverseEndian16(Memory.readword(startAddress + 21))
	local spatk = Utils.reverseEndian16(Memory.readword(startAddress + 23))
	local attack= Memory.readdword(startAddress+8)
	local move_pp= Memory.readdword(startAddress+25)
	local train_id =Memory.readword(startAddress+12)


	return {
		personality = id,
		nickname = MiscData.InternalID[id],
		trainerID = "enemy",
		pokemonID = species,
		heldItem = nil,
		experience = 0,
		friendship = 0,
		level = cur_level,
		nature = 0,
		isEgg = 0, -- [0 or 1] to determine if mon is still an egg (1 if true)
		abilityNum = abilityNum,
		status = status_result,
		sleep_turns = sleep_turns_result,
		curHP = curr_hp,
		stats = {
			hp = maxhp,
			atk = attack1,
			def = def,
			spa = spatk,

			spe = sped,
		},
		statStages = { hp = 7, atk = 7, def = 7, spa = 7, spd = 7, spe = 7, acc = 7, eva = 7 },
		moves = {
			{ id = Utils.getbits(attack, 0, 8), level = 1, pp = Utils.getbits(move_pp, 0, 8) },
			{ id = Utils.getbits(attack, 8, 8), level = 1, pp = Utils.getbits(move_pp, 8, 8) },
			{ id = Utils.getbits(attack, 16, 8), level = 1, pp = Utils.getbits(move_pp, 16, 8) },
			{ id = Utils.getbits(attack, 24, 8), level = 1, pp = Utils.getbits(move_pp, 24, 8) },
		},

		-- Unused data that can be added back in later
		-- secretID = Utils.getbits(otid, 16, 16), -- Unused
		-- pokerus = Utils.getbits(misc1, 0, 8), -- Unused
		-- iv = misc2,
		-- ev1 = effort1,
		-- ev2 = effort2,
	}
end



-- Returns two values [numAlive, total] for a given Trainer's Pokémon team.
function Program.getTeamCounts()
	local numAlive, total = 0, 0
	for i = 1, 6, 1 do
		local pokemon = Tracker.getPokemon(i, false)
		if pokemon ~= nil and PokemonData.isValid(pokemon.pokemonID) then
			total = total + 1
			if (pokemon.curHP or 0) > 0 then
				numAlive = numAlive + 1
			end
		end
	end

	return numAlive, total
end

-- Returns two exp values that describe the amount of experience points needed to reach the next level.
-- currentExp: A value between 0 and 'totalExp'
-- totalExp: The amount of exp needed to reach the next level
function Program.getNextLevelExp(pokemonID, level, experience)
	if not PokemonData.isValid(pokemonID) or level == nil or level >= 100 or experience == nil or GameSettings.gExperienceTables == nil then
		return 0, 100 -- arbitrary returned values to indicate this information isn't found and it's 0% of the way to next level
	end

	local growthRateIndex = Memory.readbyte(GameSettings.gBaseStats + (pokemonID * 0x1C) + 0x13)
	local expTableOffset = GameSettings.gExperienceTables + (growthRateIndex * 0x194) + (level * 0x4)
	local expAtLv = Memory.readdword(expTableOffset)
	local expAtNextLv = Memory.readdword(expTableOffset + 0x4)

	local currentExp = experience - expAtLv
	local totalExp = expAtNextLv - expAtLv

	return currentExp, totalExp
end

-- Determine if the battle is a wild or trainer battle. Note, this isn't foolproof if tracker is loaded during an active battle
function Program.updateBattleEncounterType()
	local newWildBattles = 0
	local newTrainerBattles = 0

	if newWildBattles - Program.GameData.wildBattles == 1 then -- difference of +1
		Battle.isWildEncounter = true
	elseif newTrainerBattles - Program.GameData.trainerBattles == 1 then -- difference of +1
		Battle.isWildEncounter = false
	end

	Program.GameData.wildBattles = newWildBattles
	Program.GameData.trainerBattles = newTrainerBattles
end

function Program.updatePCHeals()
	-- Updates PC Heal tallies and handles auto-tracking PC Heal counts when the option is on
	-- Currently checks the total number of heals from pokecenters and from mom
	-- Does not include whiteouts, as those don't increment either of these gamestats

	-- Save blocks move and are re-encrypted right as the battle starts
	if Battle.inBattle or Battle.battleStarting then
		return
	end

	-- Make sure the player is in a map location that can perform a PC heal
	if not RouteData.Locations.CanPCHeal[Program.GameData.mapId] then
		return
	end

	local gameStat_UsedPokecenter = 0
	-- Turns out Game Freak are weird and only increment mom heals in RSE, not FRLG
	local gameStat_RestedAtHome = 0

	local combinedHeals = gameStat_UsedPokecenter + gameStat_RestedAtHome

	if combinedHeals ~= Tracker.Data.gameStatsHeals then
		-- Update the local tally if there is a new heal
		Tracker.Data.gameStatsHeals = combinedHeals
		-- Only change the displayed PC Heals count when the option is on and auto-tracking is enabled
		if Options["Track PC Heals"] and TrackerScreen.Buttons.PCHealAutoTracking.toggleState then
			if Options["PC heals count downward"] then
				-- Automatically count down
				Tracker.Data.centerHeals = Tracker.Data.centerHeals - 1
				if Tracker.Data.centerHeals < 0 then Tracker.Data.centerHeals = 0 end
			else
				-- Automatically count up
				Tracker.Data.centerHeals = Tracker.Data.centerHeals + 1
				if Tracker.Data.centerHeals > 99 then Tracker.Data.centerHeals = 99 end
			end
		end
	end
end

function Program.updateBadgesObtained()
	-- Don't bother checking badge data if in the pre-game intro screen (where old data exists)
	if not Program.isValidMapLocation() then
		return
	end

	local badgeBits = Memory.readbyte(GameSettings.badgeOffset)



	if badgeBits ~= nil then
		for index = 1, 8, 1 do
			local badgeName = "badge" .. index
			local badgeButton = TrackerScreen.Buttons[badgeName]
			local badgeState = Utils.getbits(badgeBits, index - 1, 1)
			badgeButton:updateState(badgeState)
		end
	end

end

function Program.updateMapLocation()
	local newMapId = Memory.readbyte(GameSettings.gMapHeader ) -- 0x12: mapLayoutId

	-- If the player is in a new area, auto-lookup for mGBA screen
	if not Main.IsOnBizhawk() and newMapId ~= Program.GameData.mapId then
		local isFirstLocation = Program.GameData.mapId == nil or Program.GameData.mapId == 0
		MGBA.Screens.LookupRoute:setData(newMapId, isFirstLocation)
	end
	Program.GameData.mapId = newMapId
end

-- More or less used to determine if the player has begun playing the game, returns true if so.
function Program.isValidMapLocation()

	return Program.GameData.mapId ~= nil --and Program.GameData.mapId ~= 0
end

function Program.HandleExit()
	if Main.IsOnBizhawk() then
		gui.clearImageCache()
		Drawing.clearGUI()
		client.SetGameExtraPadding(0, 0, 0, 0)
		forms.destroyall()
	end
end

-- Returns a table that contains {pokemonID, level, and moveId} of the player's Pokemon that is currently learning a new move via experience level-up.
function Program.getLearnedMoveInfoTable()

	return {
		pokemonID = nil,
		level = nil,
		moveId = nil,
	}
end

-- Useful for dynamically getting the Pokemon's types if they have changed somehow (Color change, Transform, etc)
function Program.getPokemonTypes(isOwn, isLeft)
	local ownerAddressOffset = Utils.inlineIf(isOwn, 0x0, 0x58)
	local leftAddressOffset = Utils.inlineIf(isLeft, 0x0, 0xB0)
	local typesData = Memory.readword(GameSettings.gBattleMons + 0x21 + ownerAddressOffset + leftAddressOffset)
	return {
		PokemonData.TypeIndexMap[Utils.getbits(typesData, 0, 8)],
		PokemonData.TypeIndexMap[Utils.getbits(typesData, 8, 8)],
	}
end

function Program.getePokemonTypes(isOwn, isLeft)
	local ownerAddressOffset = Utils.inlineIf(isOwn, 0x0, 0x58)
	local leftAddressOffset = Utils.inlineIf(isLeft, 0x0, 0xB0)
	local typesData = Memory.readword(GameSettings.eType)
	return {
		PokemonData.TypeIndexMap[Utils.getbits(typesData, 0, 8)],
		PokemonData.TypeIndexMap[Utils.getbits(typesData, 8, 8)],
	}
end

-- Returns true only if the player hasn't completed the catching tutorial
function Program.isInCatchingTutorial()


	return false
end

function Program.isInEvolutionScene()
	local evoInfo
	--Ruby and Sapphire reference sEvoInfo (EvoInfo struct) directly. All other Gen 3 games instead store a pointer to the EvoInfo struct which needs to be read first
	if GameSettings.game ~= 1 then
		evoInfo = Memory.readdword(GameSettings.sEvoStructPtr)
	else
		evoInfo = GameSettings.sEvoInfo
	end
	-- third byte of EvoInfo is dedicated to the taskId
	local taskID = Memory.readbyte(evoInfo + 0x2)

	--only 16 tasks possible max in gTasks
	if taskID > 15 then return false end

	--Check for Evolution Task (Task_EvolutionScene + 0x1); Task struct size is 0x28
	local taskFunc = Memory.readdword(GameSettings.gTasks + (0x28 * taskID))
	if taskFunc ~= GameSettings.Task_EvolutionScene then return false end

	--Check if the Task is active
	local isActive = Memory.readbyte(GameSettings.gTasks + (0x28 * taskID) + 0x4)
	if isActive ~= 1 then return false end

	return true
end

-- Returns true if player is in the start menu (or the subsequent pokedex/pokemon/bag/etc menus)
function Program.isInStartMenu()
	-- Current Issues:
	-- 1) Sometimes this window ID gets unset for a brief duration during the transition back to the start menu
	-- 2) This window ID doesn't exist at all in Ruby/Sapphire, yet to figure out an alternative
	if GameSettings.game == 1 then return false end -- Skip checking for Ruby/Sapphire

	local startMenuWindowId = Memory.readbyte(GameSettings.sStartMenuWindowId)
	return startMenuWindowId == 1
end

-- Pokemon is valid if it has a valid id, helditem, and each move that exists is a real move.
function Program.validPokemonData(pokemonData)
	if pokemonData == nil then return false end

	-- If the Pokemon exists, but it's ID is invalid
	if not PokemonData.isValid(pokemonData.pokemonID) and pokemonData.pokemonID ~= 0 then -- 0 = blank pokemon id

		return false
	end

	-- If the Pokemon is holding an item, and that item is invalid
	if pokemonData.heldItem ~= nil and (pokemonData.heldItem < 0 or pokemonData.heldItem > 376) then

		return false
	end

	-- For each of the Pokemon's moves that isn't blank, is that move real
	for _, move in pairs(pokemonData.moves) do

		if not MoveData.isValid(move.id) and move.id ~= 0 then -- 0 = blank move id

			return false
		end
	end

	return true
end

function Program.updateBagItems()
	if not Tracker.Data.isViewingOwn then return end

	local leadPokemon = Battle.getViewedPokemon(true)

	if leadPokemon ~= nil then
		local healingItems, evolutionStones = Program.getBagItems()
		if healingItems ~= nil then
			Tracker.Data.healingItems = Program.calcBagHealingItems(leadPokemon.stats.hp, healingItems)
		end
		if evolutionStones ~= nil then
			Program.GameData.evolutionStones = evolutionStones
		end
	end
end

function Program.updateBagItemsGen2()
	if not Tracker.Data.isViewingOwn then return end

	local leadPokemon = Battle.getViewedPokemon(true)

	if leadPokemon ~= nil then
		local healingItems, evolutionStones = Program.getBagItems()
		if healingItems ~= nil then
			Tracker.Data.healingItems = Program.calcBagHealingItems(leadPokemon.stats.hp, healingItems)
		end
		if evolutionStones ~= nil then
			Program.GameData.evolutionStones = evolutionStones
		end
	end
end



function Program.calcBagHealingItems(pokemonMaxHP, healingItemsInBag)
	local totals = {
		healing = 0,
		numHeals = 0,
	}

	-- Check for potential divide-by-zero errors
	if pokemonMaxHP == nil or pokemonMaxHP == 0 then
		return totals
	end

	-- Formatted as: healingItemsInBag[itemID] = quantity
	for itemID, quantity in pairs(healingItemsInBag) do
		local healItemData = MiscData.HealingItems[itemID]
		if healItemData ~= nil and quantity > 0 then
			local healingPercentage = 0
			if healItemData.type == MiscData.HealingType.Constant then
				local percentage = healItemData.amount / pokemonMaxHP * 100
				if percentage > 100 then
					percentage = 100
				end
				healingPercentage = percentage * quantity
			elseif healItemData.type == MiscData.HealingType.Percentage then
				healingPercentage = healItemData.amount * quantity
			end
			-- Healing is in a percentage compared to the mon's max HP
			totals.healing = totals.healing + healingPercentage
			totals.numHeals = totals.numHeals + quantity
		end
	end

	return totals
end

function Program.getBagItems()
	local healingItems = {}



	local evoStones = {
		[93] = 0, -- Sun Stone
		[94] = 0, -- Moon Stone
		[95] = 0, -- Fire Stone
		[96] = 0, -- Thunder Stone
		[97] = 0, -- Water Stone
		[98] = 0, -- Leaf Stone
	}
	local size=20
	if GameSettings.GEN==2 then  size=20
	else	 size=Memory.readbyte(GameSettings.bagPocket_Items_Size) end
	local address =GameSettings.bagPocket_Items_offset
		for i = 0, (size - 1), 1 do
			--read 4 bytes at once, should be less expensive than reading two sets of 2 bytes.
			local itemid_and_quantity = Memory.readword(address + i * 0x2)
			local itemID = Utils.getbits(itemid_and_quantity, 0, 8)

			if itemID ~= 0 then
				local quantity = Utils.getbits(itemid_and_quantity, 8, 8)


				if MiscData.HealingItems[itemID] ~= nil then
					healingItems[itemID] = quantity
				elseif MiscData.EvolutionStones[itemID] ~= nil then
					evoStones[itemID] = quantity
				end
			end
		end


	return healingItems, evoStones
end
