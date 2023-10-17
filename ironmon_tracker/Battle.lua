Battle = {
	totalBattles = 0,
	inBattle = false,
	battleStarting = false,
	isWildEncounter = false,
	isGhost = false,
	opposingTrainerId = 0,
	defeatedSteven = false, -- Used exclusively for Emerald
	isViewingLeft = true, -- By default, out of battle should view the left combatant slot (index = 0)
	numBattlers = 0,
	partySize = 6,
	isNewTurn = true,
	oppTurn = 0,
	lastTurnAddedAMove = 0,
	-- "Low accuracy" values
	battleMsg = 0,
	battler = 0, -- 0 or 2 if player, 1 or 3 if enemy
	battlerTarget = 0,
	-- "High accuracy" values
	attacker = 0, -- 0 or 2 if player, 1 or 3 if enemy
	turnCount = -1,
	prevDamageTotal = 0,
	damageReceived = 0,
	lastEnemyMoveId = 0,
	enemyHasAttacked = false,
	firstActionTaken = false,
	-- "Low accuracy" values
	Synchronize = {
		turnCount = 0,
		battler = -1,
		attacker = -1,
		battlerTarget = -1
	},
	AbilityChangeData = {
		prevAction = 4,
		recordNextMove = false
	},
	-- "Low accuracy" values
	CurrentRoute = {
		encounterArea = RouteData.EncounterArea.LAND,
		hasInfo = false
	},
	-- A "Combatant" is a Pokemon that is visible on the battle screen, represented by the slot # in the owner's team [1-6].
	Combatants = {
		LeftOwn = 1,
		LeftOther = 1,
		RightOwn = 2,
		RightOther = 2
	},
	BattleParties = {
		[0] = {},
		[1] = {}
	}
}

-- Game Code maps the combatants in battle as follows: OwnTeamIndexes [L=0, R=2], EnemyTeamIndexes [L=1, R=3]
Battle.IndexMap = {
	[0] = "LeftOwn",
	[1] = "LeftOther",
	[2] = "RightOwn",
	[3] = "RightOther"
}

Battle.EnemyTrainersToHideAlly = {
	[1] = {}, -- Ruby/Sapphire
	[2] = {
		-- Emerald
		[514] = true, -- Tabitha (duo)
		[734] = true -- Maxie (duo)
	},
	[3] = {} -- FRLG
}

function Battle.update()
	if not Program.isValidMapLocation() then
		return
	end

	if Program.Frames.highAccuracyUpdate == 0 and not Program.inCatchingTutorial then
		Battle.updateBattleStatus()
	end

	if not Battle.inBattle then
		-- For cases when closing the Tracker mid battle and loading it after battle
		if not Tracker.Data.isViewingOwn then
			Tracker.Data.isViewingOwn = true
		end
		return
	end

	if Program.Frames.highAccuracyUpdate == 0 then
		Battle.updateHighAccuracy()
	end
	if Program.Frames.lowAccuracyUpdate == 0 then
		-- wip will need changes

		Battle.updateLowAccuracy()

		CustomCode.afterBattleDataUpdate()
	end
end

function Battle.updateGen2()
	if not Program.isValidMapLocation() then
		return
	end

	if Program.Frames.highAccuracyUpdate == 0 and not Program.inCatchingTutorial then
		Battle.updateBattleStatusGen2()
	end

	if not Battle.inBattle then
		-- For cases when closing the Tracker mid battle and loading it after battle
		if not Tracker.Data.isViewingOwn then
			Tracker.Data.isViewingOwn = true
		end
		return
	end

	if Program.Frames.highAccuracyUpdate == 0 then
		Battle.updateHighAccuracyGen2()
	end
	if Program.Frames.lowAccuracyUpdate == 0 then
		-- wip will need changes

		Battle.updateLowAccuracyGen2()

		CustomCode.afterBattleDataUpdate()
	end
end

function Battle.updateBattleStatusGen2()
	-- BattleStatus [0 = Not in Battle, 1 = Wild Battle, 2 = Trainer Battle]
	local lastBattleStatus = Memory.readbyte(GameSettings.gBattleTypeFlags)
	local opposingPokemon = Tracker.getPokemonGen2(1, false) -- get the lead pokemon on the enemy team
	--local totalBattles = Utils.getGameStat(Constants.GAME_STATS.TOTAL_BATTLES)
	--if Battle.totalBattles ~= 0 and (Battle.totalBattles < totalBattles) then
	--	Battle.battleStarting = true
	--end
	--Battle.totalBattles = totalBattles

	if not Battle.inBattle and lastBattleStatus ~= 0 and opposingPokemon ~= nil then
		-- Battle.isWildEncounter = Tracker.Data.trainerID == opposingPokemon.trainerID -- NOTE: doesn't work well, temporarily removing
		DataHelper.Gameover = false

		Battle.beginNewBattleGen2()
	elseif Battle.inBattle and (lastBattleStatus == 0 or opposingPokemon == nil) then
		Battle.endCurrentBattleGen2()
	end
	local lead = Tracker.getPokemonGen2(1, true)
	if lead ~= nil then
		if lastBattleStatus == 0 and lead.curHP == 0 and not DataHelper.Gameover then -- should occur exactly once per lost battle
			DataHelper.Gameover = true
			if not Battle.isWildEncounter then
				GameOverScreen.incrementLosses()
			end
			GameOverScreen.randomizeAnnouncerQuote()
			GameOverScreen.nextTeamPokemon()
			Program.changeScreenView(GameOverScreen)
		end
	end
end

function Battle.beginNewBattleGen2()
	if Battle.inBattle then
		return
	end

	GameOverScreen.createTempSaveState()

	Program.updateBattleEncounterType()

	Program.Frames.battleDataDelay = 30

	-- If this is a new battle, reset views and other pokemon tracker info
	Battle.inBattle = true
	Battle.battleStarting = false
	Battle.turnCount = 0
	Battle.prevDamageTotal = 0
	Battle.damageReceived = 0
	Battle.enemyHasAttacked = false
	Battle.firstActionTaken = false
	Battle.AbilityChangeData.prevAction = 4
	Battle.AbilityChangeData.recordNextMove = false
	Battle.Synchronize.turnCount = 0
	Battle.Synchronize.attacker = -1
	Battle.Synchronize.battlerTarget = -1
	-- RS allocated a dword for the party size

	Battle.partySize = Memory.readbyte(GameSettings.gPlayerPartyCount)

	Battle.opposingTrainerId = Memory.readword(GameSettings.estats)

	Tracker.Data.isViewingOwn = not Options["Auto swap to enemy"]
	-- If the player hasn't fought the Rival yet, use this to determine their pokemon team based on starter ball selection
	if Tracker.Data.whichRival == nil then
		Tracker.tryTrackWhichRival(Battle.opposingTrainerId)
	end

	Battle.isViewingLeft = true
	Battle.Combatants = {
		LeftOwn = 1,
		LeftOther = 1,
		RightOwn = 2,
		RightOther = 2
	}

	Battle.populateBattlePartyObjectGen2()
	Input.StatHighlighter:resetSelectedStat()

	-- Handles a common case of looking up a move, then entering combat. As a battle begins, the move info screen should go away.
	if Program.currentScreen == InfoScreen then
		InfoScreen.clearScreenData()
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == MoveHistoryScreen then
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == TypeDefensesScreen then
		Program.currentScreen = TrackerScreen
	end

	-- Delay drawing the new pokemon (or effectiveness of your own), because of send out animation
	Program.Frames.waitToDraw = Utils.inlineIf(Battle.isWildEncounter, 150, 250)

	if not Main.IsOnBizhawk() then
		MGBA.Screens.LookupPokemon.manuallySet = false
	end

	CustomCode.afterBattleBegins()
end

function Battle.endCurrentBattleGen2()
	if not Battle.inBattle then
		return
	end

	-- Only record Last Level Seen after the battle, so the info shown doesn't get overwritten by current level
	Tracker.recordLastLevelsSeen()

	--Most of the time, Run Away message is present only after the battle ends
	--Battle.battleMsg = Memory.readdword(GameSettings.gBattlescriptCurrInstr)
	--if Battle.battleMsg == GameSettings.BattleScript_RanAwayUsingMonAbility then
	--	local battleMon = Battle.BattleParties[0][Battle.Combatants[Battle.IndexMap[0]]]
	--	local abilityOwner = Tracker.getPokemon(battleMon.abilityOwner.slot,battleMon.abilityOwner.isOwn)
	--	if abilityOwner ~= nil then
	--		Tracker.TrackAbility(abilityOwner.pokemonID, battleMon.ability)
	--	end
	--end

	Battle.numBattlers = 0
	Battle.partySize = 6
	Battle.inBattle = false
	Battle.battleStarting = false
	Battle.isWildEncounter = false -- default battle type is trainer battle
	Battle.turnCount = -1
	Battle.lastEnemyMoveId = 0
	Battle.actualEnemyMoveId = 0
	Battle.Synchronize.turnCount = 0
	Battle.Synchronize.attacker = -1
	Battle.Synchronize.battlerTarget = -1

	Battle.isGhost = false

	Battle.CurrentRoute.hasInfo = false

	Tracker.Data.isViewingOwn = true
	Battle.isViewingLeft = true
	Battle.Combatants = {
		LeftOwn = 1,
		LeftOther = 1,
		RightOwn = 2,
		RightOther = 2
	}
	Battle.BattleParties = {
		[0] = {},
		[1] = {}
	}
	-- While the below clears our currently stored enemy pokemon data, most gets read back in from memory anyway
	Tracker.Data.otherPokemon = {}
	Tracker.Data.otherTeam = {0, 0, 0, 0, 0, 0}

	-- Reset stat stage changes for the owner's pokemon team
	for i = 1, 6, 1 do
		local pokemon = Tracker.getPokemon(i, true)
		if pokemon ~= nil then
			pokemon.statStages = {hp = 7, atk = 7, def = 7, spa = 7, spd = 7, spe = 7, acc = 7, eva = 7}
		end
	end

	--local lastBattleStatus = Memory.readbyte(GameSettings.gBattleOutcome)

	-- Handles a common case of looking up a move, then moving on with the current battle. As the battle ends, the move info screen should go away.
	if Program.currentScreen == InfoScreen then
		InfoScreen.clearScreenData()
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == MoveHistoryScreen then
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == TypeDefensesScreen then
		Program.currentScreen = TrackerScreen
	--elseif GameSettings.game == 2 and Battle.opposingTrainerId == 804 and lastBattleStatus == 1 then -- Emerald only, 804 = Steven, status(1) = Win
	--	Battle.defeatedSteven = true
	--	Program.currentScreen = GameOverScreen
	end

	Battle.opposingTrainerId = 0

	-- Delay drawing the return to viewing your pokemon screen
	Program.Frames.waitToDraw = Utils.inlineIf(Battle.isWildEncounter, 70, 150)
	Program.Frames.saveData = Utils.inlineIf(Battle.isWildEncounter, 70, 150) -- Save data after every battle

	CustomCode.afterBattleEnds()
end

function Battle.populateBattlePartyObjectGen2()
	--populate BattleParties for all Pokemon with their starting Abilities and pokemonIDs
	Battle.BattleParties[0] = {}
	Battle.BattleParties[1] = {}
	for i = 1, 1, 1 do
		local ownPokemon = Tracker.getPokemonGen2(i, true)

		if ownPokemon ~= nil then
			local ownMoves = {
				ownPokemon.moves[1].id,
				ownPokemon.moves[2].id,
				ownPokemon.moves[3].id,
				ownPokemon.moves[4].id
			}
			local ability = ""
			Battle.BattleParties[0][i] = {
				abilityOwner = {
					isOwn = true,
					slot = i
				},
				["originalAbility"] = ability,
				["ability"] = ability,
				transformData = {
					isOwn = true,
					slot = i
				},
				moves = ownMoves
			}
		end
		local enemyPokemon = Tracker.getPokemonGen2(i, false)
		if enemyPokemon ~= nil then
			local enemyMoves = {
				enemyPokemon.moves[1].id,
				enemyPokemon.moves[2].id,
				enemyPokemon.moves[3].id,
				enemyPokemon.moves[4].id
			}
			local ability = ""
			Battle.BattleParties[1][i] = {
				abilityOwner = {
					isOwn = false,
					slot = i
				},
				["originalAbility"] = ability,
				["ability"] = ability,
				transformData = {
					isOwn = false,
					slot = i
				},
				moves = enemyMoves
			}
		end
	end
end

function Battle.updateHighAccuracyGen2()
	Battle.processBattleTurnGen2()
end

-- Updates once every [30] frames.
function Battle.updateLowAccuracyGen2()
	Battle.updateViewSlots()
	Battle.updateTrackedInfoGen2()

	Battle.updateLookupInfo()
end
function Battle.processBattleTurnGen2()
	-- attackerValue = 0 or 2 for player mons and 1 or 3 for enemy mons (2,3 are doubles partners)

	local currentTurn = Memory.readbyte(GameSettings.gTurn)

	-- As a new turn starts, note the previous amount of total damage, reset turn counters
	if currentTurn ~= Battle.turnCount then
		Battle.turnCount = currentTurn
		Battle.prevDamageTotal = 0
		Battle.enemyHasAttacked = false
		Battle.isNewTurn = true
	end

	-- Check current and previous attackers to see if enemy attacked within the last 30 frames

	local enemyMoveId = Memory.readbyte(GameSettings.eMove)
	if enemyMoveId ~= 0 then
		-- If a new move is being used, reset the damage from the last move
		if not Battle.enemyHasAttacked then
			Battle.damageReceived = 0
			Battle.enemyHasAttacked = true
		end

		Battle.lastEnemyMoveId = enemyMoveId
		Battle.actualEnemyMoveId = enemyMoveId
	end

	-- Track moves for transformed mons if applicable; need high accuracy checking since moves window can be opened an closed in < .5 second
	--Battle.trackTransformedMoves()
end

function Battle.updateTrackedInfoGen2()
	--Ghost battle info is immediately loaded. If we wait until after the delay ends, the user can toggle views in that window and still see the 'Actual' Pokemon.
	--local battleFlags = Memory.readdword(GameSettings.gBattleTypeFlags)
	--If this is a Ghost battle (bit 15), and the Silph Scope has not been obtained (bit 13). Also, game must be FR/LG
	--Battle.isGhost = GameSettings.game == 3 and (Utils.getbits(battleFlags, 15, 1) == 1 and Utils.getbits(battleFlags, 13, 1) == 0)

	-- Required delay between reading Pokemon data from battle, as it takes ~N frames for old battle values to be cleared out
	if Program.Frames.battleDataDelay > 0 then
		Program.Frames.battleDataDelay = Program.Frames.battleDataDelay - 30 -- 30 for low accuracy updates
		return
	end

	-- Update useful battle values, will expand/rework this later
	--Battle.readBattleValues()
	--if Battle.isNewTurn then
	--	Battle.handleNewTurn()
	--end

	--handles this value not being cleared from the previous battle
	local lastMoveByAttacker = Memory.readbyte(GameSettings.eMove)
	local attackerSlot = Battle.Combatants[1]
	local transformData = Battle.BattleParties[1][1].transformData
	local turn = Memory.readbyte(GameSettings.gTurn)
	local oppTurn = Memory.readbyte(GameSettings.oppTurn)

	if turn == 0 then
		Battle.populateBattlePartyObjectGen2()
	end

	if oppTurn == 0 then
		lastTurnAddedAMove = 0
	end

	if not transformData.isOwn and oppTurn > lastTurnAddedAMove then
		-- Only track moves which the pokemon knew at the start of battle (in case of Sketch/Mimic)
		local attacker = Tracker.getPokemonGen2(transformData.slot, transformData.isOwn)
		if
			lastMoveByAttacker == attacker.moves[1].id or lastMoveByAttacker == attacker.moves[2].id or
				lastMoveByAttacker == attacker.moves[3].id or
				lastMoveByAttacker == attacker.moves[4].id
		 then
			if attacker ~= nil then
				Tracker.TrackMove(attacker.pokemonID, lastMoveByAttacker, attacker.level)
				lastTurnAddedAMove = oppTurn
			end
		end
	end

	--only get one chance to record
	Battle.AbilityChangeData.recordNextMove = false

	-- Always track your own Pokemons' abilities, unless you are in a half-double battle alongside an NPC (3 + 3 vs 3 + 3)
	local ownLeftPokemon = Tracker.getPokemon(Battle.Combatants.LeftOwn, true)
	Battle.updateStatStagesGen2(ownLeftPokemon, true)
	if ownLeftPokemon ~= nil and Battle.Combatants.LeftOwn <= Battle.partySize then
		local ownLeftAbilityId = PokemonData.getAbilityId(ownLeftPokemon.pokemonID, ownLeftPokemon.abilityNum)
	--Tracker.TrackAbility(ownLeftPokemon.pokemonID, ownLeftAbilityId)
	end

	--Don't track anything for Ghost opponents

	local otherLeftPokemon = Tracker.getPokemon(transformData.slot, false)

	if otherLeftPokemon ~= nil then
		Battle.updateStatStagesGen2(otherLeftPokemon, false)

	--Battle.checkEnemyEncounter(otherLeftPokemon)
	end

	function Battle.readBattleValues()
		Battle.numBattlers = Memory.readbyte(GameSettings.gBattlersCount)
		Battle.battleMsg = Memory.readdword(GameSettings.gBattlescriptCurrInstr)
		Battle.battler = Memory.readbyte(GameSettings.gBattleScriptingBattler) % Battle.numBattlers
		Battle.battlerTarget = Memory.readbyte(GameSettings.gBattlerTarget) % Battle.numBattlers
	end

	-- If the pokemon doesn't belong to the player, and hasn't been encountered yet, increment
	function Battle.checkEnemyEncounter(opposingPokemon)
		if opposingPokemon.hasBeenEncountered then
			return
		end

		opposingPokemon.hasBeenEncountered = true
		Tracker.TrackEncounter(opposingPokemon.pokemonID, Battle.isWildEncounter)

		--local battleTerrain = Memory.readword(GameSettings.gBattleTerrain)
		--local battleFlags = Memory.readdword(GameSettings.gBattleTypeFlags)

		--Battle.CurrentRoute.encounterArea = RouteData.getEncounterAreaByTerrain(battleTerrain, battleFlags)

		-- Check if fishing encounter, if so then get the rod that was used
		--local gameStat_FishingCaptures = Utils.getGameStat(Constants.GAME_STATS.FISHING_CAPTURES)
		--if gameStat_FishingCaptures ~= Tracker.Data.gameStatsFishing then
		--	Tracker.Data.gameStatsFishing = gameStat_FishingCaptures

		--	local fishingRod = Memory.readword(GameSettings.gSpecialVar_ItemId)
		--	if RouteData.Rods[fishingRod] ~= nil then
		--			Battle.CurrentRoute.encounterArea = RouteData.Rods[fishingRod]
		--		end
	end

	-- Check if rock smash encounter, if so then check encounter happened
	--	local gameStat_UsedRockSmash = Utils.getGameStat(Constants.GAME_STATS.USED_ROCK_SMASH)
	--	if gameStat_UsedRockSmash > Tracker.Data.gameStatsRockSmash then
	---	Tracker.Data.gameStatsRockSmash = gameStat_UsedRockSmash
	---
	--		local rockSmashResult = Memory.readword(GameSettings.gSpecialVar_Result)
	--		if rockSmashResult == 1 then
	--			Battle.CurrentRoute.encounterArea = RouteData.EncounterArea.ROCKSMASH
	--		end
	--	end

	--	Battle.CurrentRoute.hasInfo = RouteData.hasRouteEncounterArea(Program.GameData.mapId, Battle.CurrentRoute.encounterArea)

	--	if Battle.isWildEncounter and Battle.CurrentRoute.hasInfo then
	--		Tracker.TrackRouteEncounter(Program.GameData.mapId, Battle.CurrentRoute.encounterArea, opposingPokemon.pokemonID)
	--end
end

-- Check if we can enter battle (opposingPokemon check required for lab fight), or if a battle has just finished
function Battle.updateBattleStatus()
	-- BattleStatus [0 = In battle, 1 = Won the match, 2 = Lost the match, 4 = Fled, 7 = Caught]
	local lastBattleStatus = Memory.readbyte(GameSettings.gBattleTypeFlags)
	local opposingPokemon = Tracker.getPokemon(1, false) -- get the lead pokemon on the enemy team
	--local totalBattles = Utils.getGameStat(Constants.GAME_STATS.TOTAL_BATTLES)
	--if Battle.totalBattles ~= 0 and (Battle.totalBattles < totalBattles) then
	--	Battle.battleStarting = true
	--end
	--Battle.totalBattles = totalBattles

	if not Battle.inBattle and lastBattleStatus ~= 0 and opposingPokemon ~= nil then
		-- Battle.isWildEncounter = Tracker.Data.trainerID == opposingPokemon.trainerID -- NOTE: doesn't work well, temporarily removing
		DataHelper.Gameover = false

		Battle.beginNewBattle()
	elseif Battle.inBattle and (lastBattleStatus == 0 or opposingPokemon == nil) then
		Battle.endCurrentBattle()
	end
	local lead = Tracker.getPokemon(1, true)
	if lead ~= nil then
		if lastBattleStatus == 0 and lead.curHP == 0 and not DataHelper.Gameover then -- should occur exactly once per lost battle
			DataHelper.Gameover = true
			if not Battle.isWildEncounter then
				GameOverScreen.incrementLosses()
			end
			GameOverScreen.randomizeAnnouncerQuote()
			GameOverScreen.nextTeamPokemon()
			Program.changeScreenView(GameOverScreen)
		end
	end
end

-- Updates once every [10] frames. Be careful adding too many things to this 10 frame update
function Battle.updateHighAccuracy()
	Battle.processBattleTurn()
end

-- Updates once every [30] frames.
function Battle.updateLowAccuracy()
	Battle.updateViewSlots()
	Battle.updateTrackedInfo()

	Battle.updateLookupInfo()
end

-- isOwn: true if it belongs to the player; false otherwise
function Battle.getViewedPokemon(isOwn)
	local viewSlot

	viewSlot = 1

	return Tracker.getPokemon(viewSlot, isOwn)
end

function Battle.updateViewSlots()
	local prevEnemyPokemonLeft = Battle.Combatants.LeftOther
	local prevEnemyPokemonRight = Battle.Combatants.RightOther
	local prevOwnPokemonLeft = Battle.Combatants.LeftOwn
	local prevOwnPokemonRight = Battle.Combatants.RightOwn

	--update all 2 (or 4)
	Battle.Combatants.LeftOwn = 1
	Battle.Combatants.LeftOther = Memory.readbyte(GameSettings.gBattlerPartyIndexes + 2)

	-- Verify the view slots are within bounds, and that for doubles, the pokemon is not fainted (data is not cleared if there are no remaining pokemon)
	if Battle.Combatants.LeftOwn < 1 or Battle.Combatants.LeftOwn > 6 then
		Battle.Combatants.LeftOwn = 1
	end
	if Battle.Combatants.LeftOther < 1 or Battle.Combatants.LeftOther > 6 then
		Battle.Combatants.LeftOther = 1
	end

	-- Now also track the slots of the other 2 mons in double battles
	if Battle.numBattlers == 4 then
		Battle.Combatants.RightOwn = Memory.readbyte(GameSettings.gBattlerPartyIndexes + 4) + 1
		Battle.Combatants.RightOther = Memory.readbyte(GameSettings.gBattlerPartyIndexes + 6) + 1

		if Battle.Combatants.RightOwn < 1 or Battle.Combatants.RightOwn > 6 then
			Battle.Combatants.RightOwn = Utils.inlineIf(Battle.Combatants.LeftOwn == 1, 2, 1)
		end
		if Battle.Combatants.RightOther < 1 or Battle.Combatants.RightOther > 6 then
			Battle.Combatants.RightOther = Utils.inlineIf(Battle.Combatants.LeftOther == 1, 2, 1)
		end
	end

	--Track if ally pokemon changes, to reset transform and ability changes
	if
		prevOwnPokemonLeft ~= nil and prevOwnPokemonLeft ~= Battle.Combatants.LeftOwn and
			Battle.BattleParties[0][prevOwnPokemonLeft] ~= nil
	 then
		Battle.resetAbilityMapPokemon(prevOwnPokemonLeft, true)
	elseif
		Battle.numBattlers == 4 and prevOwnPokemonRight ~= nil and prevOwnPokemonRight ~= Battle.Combatants.RightOwn and
			Battle.BattleParties[0][prevOwnPokemonRight] ~= nil
	 then
		Battle.resetAbilityMapPokemon(prevOwnPokemonRight, true)
	end
	-- Pokemon on the left is not the one that was there previously
	if
		prevEnemyPokemonLeft ~= nil and prevEnemyPokemonLeft ~= Battle.Combatants.LeftOther and
			Battle.BattleParties[1][prevEnemyPokemonLeft]
	 then
		Battle.resetAbilityMapPokemon(prevEnemyPokemonLeft, false)
		Battle.changeOpposingPokemonView(true)
	elseif
		Battle.numBattlers == 4 and prevEnemyPokemonRight ~= nil and prevEnemyPokemonRight ~= Battle.Combatants.RightOther and
			Battle.BattleParties[1][prevEnemyPokemonRight]
	 then
		Battle.resetAbilityMapPokemon(prevEnemyPokemonRight, false)
		Battle.changeOpposingPokemonView(false)
	end
end

function Battle.processBattleTurn()
	-- attackerValue = 0 or 2 for player mons and 1 or 3 for enemy mons (2,3 are doubles partners)

	local currentTurn = Memory.readbyte(GameSettings.gTurn)

	-- As a new turn starts, note the previous amount of total damage, reset turn counters
	if currentTurn ~= Battle.turnCount then
		Battle.turnCount = currentTurn
		Battle.prevDamageTotal = 0
		Battle.enemyHasAttacked = false
		Battle.isNewTurn = true
	end

	-- Check current and previous attackers to see if enemy attacked within the last 30 frames

	local enemyMoveId = Memory.readbyte(GameSettings.eMove)
	if enemyMoveId ~= 0 then
		-- If a new move is being used, reset the damage from the last move
		if not Battle.enemyHasAttacked then
			Battle.damageReceived = 0
			Battle.enemyHasAttacked = true
		end

		Battle.lastEnemyMoveId = enemyMoveId
		Battle.actualEnemyMoveId = enemyMoveId
	end

	-- Track moves for transformed mons if applicable; need high accuracy checking since moves window can be opened an closed in < .5 second
	--Battle.trackTransformedMoves()
end

function Battle.updateStatStages(pokemon, isOwn)
	local startAddress = GameSettings.StatChange + Utils.inlineIf(isOwn, 0x0, 0x14)
	local isLeftOffset = 0

	--local hp_atk_def_speed = Memory.readdword(startAddress + isLeftOffset )
	--local spatk_spdef_acc_evasion = Memory.readdword(startAddress + isLeftOffset + 0x04)

	pokemon.statStages.hp = 7
	if pokemon.statStages.hp ~= 0 then
		pokemon.statStages = {
			hp = pokemon.statStages.hp,
			atk = Memory.readbyte(startAddress),
			def = Memory.readbyte(startAddress + 1),
			spa = Memory.readbyte(startAddress + 3),
			spd = 6,
			spe = Memory.readbyte(startAddress + 2),
			acc = Memory.readbyte(startAddress + 4),
			eva = Memory.readbyte(startAddress + 5)
		}
	else
		-- Unsure if this reset is necessary, or what the if condition is checking for
		pokemon.statStages = {hp = 6, atk = 6, def = 6, spa = 6, spd = 6, spe = 6, acc = 6, eva = 6}
	end
end

function Battle.updateStatStagesGen2(pokemon, isOwn)
	local startAddress = GameSettings.StatChange + Utils.inlineIf(isOwn, 0x0, 8)
	local isLeftOffset = 0

	--local hp_atk_def_speed = Memory.readdword(startAddress + isLeftOffset )
	--local spatk_spdef_acc_evasion = Memory.readdword(startAddress + isLeftOffset + 0x04)

	pokemon.statStages.hp = 7
	if pokemon.statStages.hp ~= 0 then
		pokemon.statStages = {
			hp = pokemon.statStages.hp,
			atk = Memory.readbyte(startAddress),
			def = Memory.readbyte(startAddress + 1),
			spa = Memory.readbyte(startAddress + 3),
			spd = Memory.readbyte(startAddress + 4),
			spe = Memory.readbyte(startAddress + 2),
			acc = Memory.readbyte(startAddress + 5),
			eva = Memory.readbyte(startAddress + 6)
		}
	else
		-- Unsure if this reset is necessary, or what the if condition is checking for
		pokemon.statStages = {hp = 6, atk = 6, def = 6, spa = 6, spd = 6, spe = 6, acc = 6, eva = 6}
	end
end

function Battle.updateTrackedInfo()
	--Ghost battle info is immediately loaded. If we wait until after the delay ends, the user can toggle views in that window and still see the 'Actual' Pokemon.
	--local battleFlags = Memory.readdword(GameSettings.gBattleTypeFlags)
	--If this is a Ghost battle (bit 15), and the Silph Scope has not been obtained (bit 13). Also, game must be FR/LG
	--Battle.isGhost = GameSettings.game == 3 and (Utils.getbits(battleFlags, 15, 1) == 1 and Utils.getbits(battleFlags, 13, 1) == 0)

	-- Required delay between reading Pokemon data from battle, as it takes ~N frames for old battle values to be cleared out
	if Program.Frames.battleDataDelay > 0 then
		Program.Frames.battleDataDelay = Program.Frames.battleDataDelay - 30 -- 30 for low accuracy updates
		return
	end

	-- Update useful battle values, will expand/rework this later
	--Battle.readBattleValues()
	--if Battle.isNewTurn then
	--	Battle.handleNewTurn()
	--end

	--handles this value not being cleared from the previous battle
	local lastMoveByAttacker = Memory.readbyte(GameSettings.eMove)
	local attackerSlot = Battle.Combatants[1]
	local attacker = Battle.BattleParties[1][1]
	local transformData = Battle.BattleParties[1][1].transformData
	local trun = Memory.readbyte(GameSettings.gTurn)

	if trun == 0 then
		Battle.populateBattlePartyObject()
	end
	if not transformData.isOwn and trun ~= 0 then
		-- Only track moves which the pokemon knew at the start of battle (in case of Sketch/Mimic)
		if
			lastMoveByAttacker == attacker.moves[1] or lastMoveByAttacker == attacker.moves[2] or
				lastMoveByAttacker == attacker.moves[3] or
				lastMoveByAttacker == attacker.moves[4]
		 then
			local attackingMon = Tracker.getPokemon(transformData.slot, transformData.isOwn)

			if attackingMon ~= nil then
				Tracker.TrackMove(attackingMon.pokemonID, lastMoveByAttacker, attackingMon.level)
			end
		end
	end

	--only get one chance to record
	Battle.AbilityChangeData.recordNextMove = false

	-- Always track your own Pokemons' abilities, unless you are in a half-double battle alongside an NPC (3 + 3 vs 3 + 3)
	local ownLeftPokemon = Tracker.getPokemon(Battle.Combatants.LeftOwn, true)
	if ownLeftPokemon ~= nil and Battle.Combatants.LeftOwn <= Battle.partySize then
		local ownLeftAbilityId = PokemonData.getAbilityId(ownLeftPokemon.pokemonID, ownLeftPokemon.abilityNum)
		--Tracker.TrackAbility(ownLeftPokemon.pokemonID, ownLeftAbilityId)

		Battle.updateStatStages(ownLeftPokemon, true)
	end

	--Don't track anything for Ghost opponents

	local otherLeftPokemon = Tracker.getPokemon(transformData.slot, false)

	if otherLeftPokemon ~= nil then
		Battle.updateStatStages(otherLeftPokemon, false)

	--Battle.checkEnemyEncounter(otherLeftPokemon)
	end

	function Battle.readBattleValues()
		Battle.numBattlers = Memory.readbyte(GameSettings.gBattlersCount)
		Battle.battleMsg = Memory.readdword(GameSettings.gBattlescriptCurrInstr)
		Battle.battler = Memory.readbyte(GameSettings.gBattleScriptingBattler) % Battle.numBattlers
		Battle.battlerTarget = Memory.readbyte(GameSettings.gBattlerTarget) % Battle.numBattlers
	end

	-- If the pokemon doesn't belong to the player, and hasn't been encountered yet, increment
	function Battle.checkEnemyEncounter(opposingPokemon)
		if opposingPokemon.hasBeenEncountered then
			return
		end

		opposingPokemon.hasBeenEncountered = true
		Tracker.TrackEncounter(opposingPokemon.pokemonID, Battle.isWildEncounter)

		--local battleTerrain = Memory.readword(GameSettings.gBattleTerrain)
		--local battleFlags = Memory.readdword(GameSettings.gBattleTypeFlags)

		--Battle.CurrentRoute.encounterArea = RouteData.getEncounterAreaByTerrain(battleTerrain, battleFlags)

		-- Check if fishing encounter, if so then get the rod that was used
		--local gameStat_FishingCaptures = Utils.getGameStat(Constants.GAME_STATS.FISHING_CAPTURES)
		--if gameStat_FishingCaptures ~= Tracker.Data.gameStatsFishing then
		--	Tracker.Data.gameStatsFishing = gameStat_FishingCaptures

		--	local fishingRod = Memory.readword(GameSettings.gSpecialVar_ItemId)
		--	if RouteData.Rods[fishingRod] ~= nil then
		--			Battle.CurrentRoute.encounterArea = RouteData.Rods[fishingRod]
		--		end
	end

	-- Check if rock smash encounter, if so then check encounter happened
	--	local gameStat_UsedRockSmash = Utils.getGameStat(Constants.GAME_STATS.USED_ROCK_SMASH)
	--	if gameStat_UsedRockSmash > Tracker.Data.gameStatsRockSmash then
	---	Tracker.Data.gameStatsRockSmash = gameStat_UsedRockSmash
	---
	--		local rockSmashResult = Memory.readword(GameSettings.gSpecialVar_Result)
	--		if rockSmashResult == 1 then
	--			Battle.CurrentRoute.encounterArea = RouteData.EncounterArea.ROCKSMASH
	--		end
	--	end

	--	Battle.CurrentRoute.hasInfo = RouteData.hasRouteEncounterArea(Program.GameData.mapId, Battle.CurrentRoute.encounterArea)

	--	if Battle.isWildEncounter and Battle.CurrentRoute.hasInfo then
	--		Tracker.TrackRouteEncounter(Program.GameData.mapId, Battle.CurrentRoute.encounterArea, opposingPokemon.pokemonID)
	--end
end

function Battle.checkAbilitiesToTrack()
	-- Track previous ability activation for handling Synchronize
	if Battle.Synchronize.turnCount < Battle.turnCount then
		Battle.Synchronize.turnCount = Battle.turnCount
		Battle.Synchronize.battler = -1
		Battle.Synchronize.attacker = -1
		Battle.Synchronize.battlerTarget = -1
	end
	local combatantIndexesToTrack = {}

	--Something is not right with the data; happens occasionally for emerald.
	if
		Battle.attacker == nil or Battle.IndexMap[Battle.attacker] == nil or
			Battle.Combatants[Battle.IndexMap[Battle.attacker]] == nil or
			Battle.BattleParties[Battle.attacker % 2] == nil or
			Battle.BattleParties[Battle.attacker % 2][Battle.Combatants[Battle.IndexMap[Battle.attacker]]] == nil or
			Battle.battler == nil or
			Battle.IndexMap[Battle.battler] == nil or
			Battle.Combatants[Battle.IndexMap[Battle.battler]] == nil or
			Battle.BattleParties[Battle.battler % 2] == nil or
			Battle.BattleParties[Battle.battler % 2][Battle.Combatants[Battle.IndexMap[Battle.battler]]] == nil or
			Battle.battlerTarget == nil or
			Battle.IndexMap[Battle.battlerTarget] == nil or
			Battle.Combatants[Battle.IndexMap[Battle.battlerTarget]] == nil or
			Battle.BattleParties[Battle.battlerTarget % 2] == nil or
			Battle.BattleParties[Battle.battlerTarget % 2][Battle.Combatants[Battle.IndexMap[Battle.battlerTarget]]] == nil
	 then
		return combatantIndexesToTrack
	end

	local attackerAbility =
		Battle.BattleParties[Battle.attacker % 2][Battle.Combatants[Battle.IndexMap[Battle.attacker]]].ability
	local battlerAbility =
		Battle.BattleParties[Battle.battler % 2][Battle.Combatants[Battle.IndexMap[Battle.battler]]].ability
	local battleTargetAbility =
		Battle.BattleParties[Battle.battlerTarget % 2][Battle.Combatants[Battle.IndexMap[Battle.battlerTarget]]].ability

	-- BATTLER: 'battler' had their ability triggered
	local abilityMsg = GameSettings.ABILITIES.BATTLER[Battle.battleMsg]
	if abilityMsg ~= nil and abilityMsg[battlerAbility] then
		-- Track a Traced pokemon's ability
		if battlerAbility == 36 then
			Battle.trackAbilityChanges(nil, 36)
			combatantIndexesToTrack[Battle.battlerTarget] = Battle.battlerTarget
		end
		combatantIndexesToTrack[Battle.battler] = Battle.battler
	end

	-- REVERSE_BATTLER: 'battlerTarget' had their ability triggered by the battler's ability
	abilityMsg = GameSettings.ABILITIES.REVERSE_BATTLER[Battle.battleMsg]
	if abilityMsg ~= nil and abilityMsg[battleTargetAbility] then
		combatantIndexesToTrack[Battle.battlerTarget] = Battle.battlerTarget
		combatantIndexesToTrack[Battle.battler] = Battle.battler
	end

	-- ATTACKER: 'battleTarget' had their ability triggered
	abilityMsg = GameSettings.ABILITIES.ATTACKER[Battle.battleMsg]
	if abilityMsg ~= nil and abilityMsg[battleTargetAbility] then
		combatantIndexesToTrack[Battle.battlerTarget] = Battle.battlerTarget
	end
	--Synchronize
	if
		abilityMsg ~= nil and abilityMsg[battlerAbility] and
			(Battle.Synchronize.attacker == Battle.attacker and Battle.Synchronize.battlerTarget == Battle.battlerTarget and
				Battle.Synchronize.battler ~= Battle.battler and
				Battle.Synchronize.battlerTarget ~= -1)
	 then
		combatantIndexesToTrack[Battle.battler] = Battle.battler
	end

	-- REVERSE ATTACKER: 'attacker' had their ability triggered
	abilityMsg = GameSettings.ABILITIES.REVERSE_ATTACKER[Battle.battleMsg]
	if abilityMsg ~= nil and abilityMsg[attackerAbility] then
		combatantIndexesToTrack[Battle.attacker] = Battle.attacker
	end

	abilityMsg = GameSettings.ABILITIES.STATUS_INFLICT[Battle.battleMsg]
	if abilityMsg ~= nil then
		-- Log allied pokemon contact status ability trigger for Synchronize
		if
			abilityMsg[battlerAbility] and
				((Battle.battler == Battle.battlerTarget) or
					(Battle.Synchronize.attacker == Battle.attacker and Battle.Synchronize.battlerTarget == Battle.battlerTarget and
						Battle.Synchronize.battler ~= Battle.battler))
		 then
			combatantIndexesToTrack[Battle.battler] = Battle.battler
		end
		if abilityMsg[battleTargetAbility] then
			Battle.Synchronize.turnCount = Battle.turnCount
			Battle.Synchronize.battler = Battle.battler
			Battle.Synchronize.attacker = Battle.attacker
			Battle.Synchronize.battlerTarget = Battle.battlerTarget
		end
	end

	abilityMsg = GameSettings.ABILITIES.BATTLE_TARGET[Battle.battleMsg]
	if abilityMsg ~= nil then
		if abilityMsg[battleTargetAbility] and abilityMsg.scope == "self" then
			combatantIndexesToTrack[Battle.battlerTarget] = Battle.battlerTarget
		end
		if abilityMsg.scope == "other" and abilityMsg[attackerAbility] then
			combatantIndexesToTrack[Battle.attacker] = Battle.attacker
		end
	end

	local levitateCheck = Memory.readbyte(GameSettings.gBattleCommunication + 0x6)
	for i = 0, Battle.numBattlers - 1, 1 do
		if levitateCheck == 4 and Battle.attacker ~= i then
			--check for first Damp mon
			combatantIndexesToTrack[Battle.battlerTarget] = Battle.battlerTarget
		elseif abilityMsg ~= nil and abilityMsg.scope == "both" then
			local monAbility = Battle.BattleParties[i % 2][Battle.Combatants[Battle.IndexMap[i]]].ability
			if abilityMsg[monAbility] then
				combatantIndexesToTrack[i] = i
			end
		end
	end

	return combatantIndexesToTrack
end

function Battle.updateLookupInfo()
	if Main.IsOnBizhawk() then
		return
	end -- currently just mGBA

	if not MGBA.Screens.LookupPokemon.manuallySet and Program.Frames.waitToDraw == 0 then -- prevent changing if player manually looked up a Pokémon
		-- Auto lookup the enemy Pokémon being fought
		local pokemon = Battle.getViewedPokemon(false) or PokemonData.BlankPokemon
		MGBA.Screens.LookupPokemon:setData(pokemon.pokemonID, false)
	end
end

function Battle.beginNewBattle()
	if Battle.inBattle then
		return
	end

	GameOverScreen.createTempSaveState()

	Program.updateBattleEncounterType()

	Program.Frames.battleDataDelay = 30

	-- If this is a new battle, reset views and other pokemon tracker info
	Battle.inBattle = true
	Battle.battleStarting = false
	Battle.turnCount = 0
	Battle.prevDamageTotal = 0
	Battle.damageReceived = 0
	Battle.enemyHasAttacked = false
	Battle.firstActionTaken = false
	Battle.AbilityChangeData.prevAction = 4
	Battle.AbilityChangeData.recordNextMove = false
	Battle.Synchronize.turnCount = 0
	Battle.Synchronize.attacker = -1
	Battle.Synchronize.battlerTarget = -1
	-- RS allocated a dword for the party size

	Battle.partySize = Memory.readbyte(GameSettings.gPlayerPartyCount)

	Battle.opposingTrainerId = Memory.readword(GameSettings.estats)

	Tracker.Data.isViewingOwn = not Options["Auto swap to enemy"]
	-- If the player hasn't fought the Rival yet, use this to determine their pokemon team based on starter ball selection
	if Tracker.Data.whichRival == nil then
		Tracker.tryTrackWhichRival(Battle.opposingTrainerId)
	end

	Battle.isViewingLeft = true
	Battle.Combatants = {
		LeftOwn = 1,
		LeftOther = 1,
		RightOwn = 2,
		RightOther = 2
	}

	Battle.populateBattlePartyObject()
	Input.StatHighlighter:resetSelectedStat()

	-- Handles a common case of looking up a move, then entering combat. As a battle begins, the move info screen should go away.
	if Program.currentScreen == InfoScreen then
		InfoScreen.clearScreenData()
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == MoveHistoryScreen then
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == TypeDefensesScreen then
		Program.currentScreen = TrackerScreen
	end

	-- Delay drawing the new pokemon (or effectiveness of your own), because of send out animation
	Program.Frames.waitToDraw = Utils.inlineIf(Battle.isWildEncounter, 150, 250)

	if not Main.IsOnBizhawk() then
		MGBA.Screens.LookupPokemon.manuallySet = false
	end

	CustomCode.afterBattleBegins()
end

function Battle.endCurrentBattle()
	if not Battle.inBattle then
		return
	end

	-- Only record Last Level Seen after the battle, so the info shown doesn't get overwritten by current level
	Tracker.recordLastLevelsSeen()

	--Most of the time, Run Away message is present only after the battle ends
	--Battle.battleMsg = Memory.readdword(GameSettings.gBattlescriptCurrInstr)
	--if Battle.battleMsg == GameSettings.BattleScript_RanAwayUsingMonAbility then
	--	local battleMon = Battle.BattleParties[0][Battle.Combatants[Battle.IndexMap[0]]]
	--	local abilityOwner = Tracker.getPokemon(battleMon.abilityOwner.slot,battleMon.abilityOwner.isOwn)
	--	if abilityOwner ~= nil then
	--		Tracker.TrackAbility(abilityOwner.pokemonID, battleMon.ability)
	--	end
	--end

	Battle.numBattlers = 0
	Battle.partySize = 6
	Battle.inBattle = false
	Battle.battleStarting = false
	Battle.isWildEncounter = false -- default battle type is trainer battle
	Battle.turnCount = -1
	Battle.lastEnemyMoveId = 0
	Battle.actualEnemyMoveId = 0
	Battle.Synchronize.turnCount = 0
	Battle.Synchronize.attacker = -1
	Battle.Synchronize.battlerTarget = -1

	Battle.isGhost = false

	Battle.CurrentRoute.hasInfo = false

	Tracker.Data.isViewingOwn = true
	Battle.isViewingLeft = true
	Battle.Combatants = {
		LeftOwn = 1,
		LeftOther = 1,
		RightOwn = 2,
		RightOther = 2
	}
	Battle.BattleParties = {
		[0] = {},
		[1] = {}
	}
	-- While the below clears our currently stored enemy pokemon data, most gets read back in from memory anyway
	Tracker.Data.otherPokemon = {}
	Tracker.Data.otherTeam = {0, 0, 0, 0, 0, 0}

	-- Reset stat stage changes for the owner's pokemon team
	for i = 1, 6, 1 do
		local pokemon = Tracker.getPokemon(i, true)
		if pokemon ~= nil then
			pokemon.statStages = {hp = 6, atk = 6, def = 6, spa = 6, spd = 6, spe = 6, acc = 6, eva = 6}
		end
	end

	--local lastBattleStatus = Memory.readbyte(GameSettings.gBattleOutcome)

	-- Handles a common case of looking up a move, then moving on with the current battle. As the battle ends, the move info screen should go away.
	if Program.currentScreen == InfoScreen then
		InfoScreen.clearScreenData()
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == MoveHistoryScreen then
		Program.currentScreen = TrackerScreen
	elseif Program.currentScreen == TypeDefensesScreen then
		Program.currentScreen = TrackerScreen
	--elseif GameSettings.game == 2 and Battle.opposingTrainerId == 804 and lastBattleStatus == 1 then -- Emerald only, 804 = Steven, status(1) = Win
	--	Battle.defeatedSteven = true
	--	Program.currentScreen = GameOverScreen
	end

	Battle.opposingTrainerId = 0

	-- Delay drawing the return to viewing your pokemon screen
	Program.Frames.waitToDraw = Utils.inlineIf(Battle.isWildEncounter, 70, 150)
	Program.Frames.saveData = Utils.inlineIf(Battle.isWildEncounter, 70, 150) -- Save data after every battle

	CustomCode.afterBattleEnds()
end

function Battle.resetBattle()
	local oldSaveDataFrames = Program.Frames.saveData
	Battle.endCurrentBattle()
	Battle.beginNewBattle()
	Program.Frames.waitToDraw = 60
	Program.Frames.saveData = oldSaveDataFrames
end

function Battle.handleNewTurn()
	--Reset counters
	Battle.AbilityChangeData.prevAction = 4
	Battle.AbilityChangeData.recordNextMove = false
	Battle.isNewTurn = false
end

function Battle.changeOpposingPokemonView(isLeft)
	if Options["Auto swap to enemy"] then
		Tracker.Data.isViewingOwn = false
		Battle.isViewingLeft = isLeft
		if not Main.IsOnBizhawk() then
			MGBA.Screens.LookupPokemon.manuallySet = false
		end
	end

	Input.StatHighlighter:resetSelectedStat()

	-- Delay drawing the new pokemon, because of send out animation
	Program.Frames.waitToDraw = 0
end

function Battle.populateBattlePartyObject()
	--populate BattleParties for all Pokemon with their starting Abilities and pokemonIDs
	Battle.BattleParties[0] = {}
	Battle.BattleParties[1] = {}
	for i = 1, 1, 1 do
		local ownPokemon = Tracker.getPokemon(i, true)

		if ownPokemon ~= nil then
			local ownMoves = {
				ownPokemon.moves[1].id,
				ownPokemon.moves[2].id,
				ownPokemon.moves[3].id,
				ownPokemon.moves[4].id
			}
			local ability = ""
			Battle.BattleParties[0][i] = {
				abilityOwner = {
					isOwn = true,
					slot = i
				},
				["originalAbility"] = ability,
				["ability"] = ability,
				transformData = {
					isOwn = true,
					slot = i
				},
				moves = ownMoves
			}
		end
		local enemyPokemon = Tracker.getPokemon(i, false)
		if enemyPokemon ~= nil then
			local enemyMoves = {
				enemyPokemon.moves[1].id,
				enemyPokemon.moves[2].id,
				enemyPokemon.moves[3].id,
				enemyPokemon.moves[4].id
			}
			local ability = ""
			Battle.BattleParties[1][i] = {
				abilityOwner = {
					isOwn = false,
					slot = i
				},
				["originalAbility"] = ability,
				["ability"] = ability,
				transformData = {
					isOwn = false,
					slot = i
				},
				moves = enemyMoves
			}
		end
	end
end

function Battle.trackAbilityChanges(moveUsed, ability)
	--check if ability changing move is being used. If so, make appropriate swaps in the table based on attacker/target
	if moveUsed ~= nil and moveUsed ~= 0 then
		if moveUsed == 285 then
			--Skill Swap; swap abilities and sources of target and attacker
			local attackerTeamIndex = Battle.attacker % 2
			local attackerSlot = Battle.Combatants[Battle.IndexMap[Battle.attacker]]
			local targetTeamIndex = Battle.battlerTarget % 2
			local targetSlot = Battle.Combatants[Battle.IndexMap[Battle.battlerTarget]]

			local tempOwnerIsOwn = Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.isOwn
			local tempOwnerSlot = Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.slot
			local tempAbility = Battle.BattleParties[attackerTeamIndex][attackerSlot].ability

			Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.isOwn =
				Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.isOwn
			Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.slot =
				Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.slot
			Battle.BattleParties[attackerTeamIndex][attackerSlot].ability =
				Battle.BattleParties[targetTeamIndex][targetSlot].ability
			Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.isOwn = tempOwnerIsOwn
			Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.slot = tempOwnerSlot
			Battle.BattleParties[targetTeamIndex][targetSlot].ability = tempAbility
		elseif moveUsed == 272 or moveUsed == 144 then
			--Role Play/Transform; copy abilities and sources of target and attacker, and turn on/off transform tracking
			local attackerTeamIndex = Battle.attacker % 2
			local attackerSlot = Battle.Combatants[Battle.IndexMap[Battle.attacker]]
			local targetTeamIndex = Battle.battlerTarget % 2
			local targetSlot = Battle.Combatants[Battle.IndexMap[Battle.battlerTarget]]

			if moveUsed == 272 then
				local abilityOwner =
					Tracker.getPokemon(
					Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.slot,
					Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.isOwn
				)
				if abilityOwner ~= nil then
					Tracker.TrackAbility(abilityOwner.pokemonID, Battle.BattleParties[targetTeamIndex][targetSlot].ability)
				end
			end

			Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.isOwn =
				Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.isOwn
			Battle.BattleParties[attackerTeamIndex][attackerSlot].abilityOwner.slot =
				Battle.BattleParties[targetTeamIndex][targetSlot].abilityOwner.slot
			Battle.BattleParties[attackerTeamIndex][attackerSlot].ability =
				Battle.BattleParties[targetTeamIndex][targetSlot].ability

			--Track Transform changes
			if moveUsed == 144 then
				Battle.BattleParties[attackerTeamIndex][attackerSlot].transformData.isOwn =
					Battle.BattleParties[targetTeamIndex][targetSlot].transformData.isOwn
				Battle.BattleParties[attackerTeamIndex][attackerSlot].transformData.slot =
					Battle.BattleParties[targetTeamIndex][targetSlot].transformData.slot
			end
		end
	elseif ability ~= nil and ability ~= 0 then
		if ability == 36 then --Trace
			-- In double battles, Trace picks a random target, so we need to grab the battle index from the text variable, gBattleTextBuff1[2]
			local tracerTeamIndex = Battle.battler % 2
			local tracerTeamSlot = Battle.Combatants[Battle.IndexMap[Battle.battler]]
			local target = Memory.readbyte(GameSettings.gBattleTextBuff1 + 2)
			local targetTeamIndex = target % 2
			local targetTeamSlot = Battle.Combatants[Battle.IndexMap[target]]

			--Track Trace here, otherwise when we try to track normally, the pokemon's battle ability and owner will have already updated to what was traced.
			local abilityOwner =
				Tracker.getPokemon(
				Battle.BattleParties[tracerTeamIndex][tracerTeamSlot].abilityOwner.slot,
				Battle.BattleParties[tracerTeamIndex][tracerTeamSlot].abilityOwner.isOwn
			)
			if abilityOwner ~= nil then
				Tracker.TrackAbility(abilityOwner.pokemonID, ability)
			end

			Battle.BattleParties[tracerTeamIndex][tracerTeamSlot].abilityOwner.isOwn =
				Battle.BattleParties[targetTeamIndex][targetTeamSlot].abilityOwner.isOwn
			Battle.BattleParties[tracerTeamIndex][tracerTeamSlot].abilityOwner.slot =
				Battle.BattleParties[targetTeamIndex][targetTeamSlot].abilityOwner.slot
			Battle.BattleParties[tracerTeamIndex][tracerTeamSlot].ability =
				Battle.BattleParties[targetTeamIndex][targetTeamSlot].ability
		end
	end
end

function Battle.resetAbilityMapPokemon(slot, isOwn)
	local teamIndex = Utils.inlineIf(isOwn, 0, 1)
	Battle.BattleParties[teamIndex][slot].abilityOwner.isOwn = isOwn
	Battle.BattleParties[teamIndex][slot].abilityOwner.slot = slot
	Battle.BattleParties[teamIndex][slot].ability = Battle.BattleParties[teamIndex][slot].originalAbility

	Battle.BattleParties[teamIndex][slot].transformData.isOwn = isOwn
	Battle.BattleParties[teamIndex][slot].transformData.slot = slot
end

function Battle.trackTransformedMoves()
	--Do nothing if no pokemon is viewing their moves
	if Memory.readbyte(GameSettings.sBattleBuffersTransferData) ~= 20 then
		return
	end

	-- First 4 bits indicate attacker
	local currentSelectingMon = Utils.getbits(Memory.readbyte(GameSettings.gBattleControllerExecFlags), 0, 4)

	-- Get 0 or 2 battler Index (bitshift the bits until you find the 1)
	for i = 0, 3, 1 do
		if currentSelectingMon == 1 then
			currentSelectingMon = i
			break
		else
			currentSelectingMon = Utils.bit_rshift(currentSelectingMon, 1)
		end
	end

	-- somehow got an enemy Pokemon's ID
	if currentSelectingMon % 2 ~= 0 then
		return
	end

	-- Track all moves, if we are copying an enemy mon
	local transformData = Battle.BattleParties[0][Battle.Combatants[Battle.IndexMap[currentSelectingMon]]].transformData
	if not transformData.isOwn or transformData.slot > Battle.partySize then
		local copiedMon = Tracker.getPokemon(transformData.slot, false)
		if copiedMon ~= nil then
			for _, move in pairs(copiedMon.moves) do
				Tracker.TrackMove(copiedMon.pokemonID, move.id, copiedMon.level)
			end
		end
	end
end

function Battle.moveDelayed()
	return Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsConfused or -- Pause for "X is confused"
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsConfused2 or -- Confusion animation
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsConfusedNoMore or -- Pause for "X snapped out of confusion"
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsInLove or -- Pause for the "X is in love with Y" delay
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsInLove2 or --Infatuation animation
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsFrozen or -- Ignore "X is frozen solid"
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsFrozen2 or -- Frozen animation
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedIsFrozen3 or -- Frozen animation 2
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedUnfroze or -- Pause for "X thawed out"
		Battle.battleMsg == GameSettings.BattleScript_MoveUsedUnfroze2 -- Thawed out 2
end

-- During double battles, this is the Pokemon the targeting cursor is pointing at (either enemy or your partner)
-- Returns: targetInfo table { slot(1-6), target(0,2,1,3), isLeft(true/false), isOwner(true/false) }
function Battle.getDoublesCursorTargetInfo()
	-- target: top row are enemies, bottom row are owners
	-- 3 1
	-- 0 2
	local targetInfo = {}

	if Tracker.Data.isViewingOwn then
		targetInfo.slot = Battle.Combatants.LeftOther
		targetInfo.target = 1
		targetInfo.isLeft = true
		targetInfo.isOwner = false
	else
		targetInfo.slot = Battle.Combatants.LeftOwn
		targetInfo.target = 0
		targetInfo.isLeft = true
		targetInfo.isOwner = true
	end

	if Battle.numBattlers == 2 then
		return targetInfo
	end

	-- For doubles: use the other pokemon if the primary pokemon is KO'd
	local leftPokemon = Tracker.getPokemon(targetInfo.slot, targetInfo.isOwner)
	if leftPokemon ~= nil and (leftPokemon.curHP or 0) == 0 then
		targetInfo.slot = Utils.inlineIf(targetInfo.isOwner, Battle.Combatants.RightOwn, Battle.Combatants.RightOther)
		targetInfo.target = Utils.inlineIf(targetInfo.isOwner, 2, 3)
		targetInfo.isLeft = false
	end

	-- Viewing an enemy pokemon should always calc stats against your default pokemon; Also, not all games have this address
	if not Tracker.Data.isViewingOwn or GameSettings.gMultiUsePlayerCursor == nil then
		return targetInfo
	end

	local target = Memory.readbyte(GameSettings.gMultiUsePlayerCursor)
	if target < 0 or target > 4 then
		-- If no is target selected, the value is 255
		return targetInfo
	end

	targetInfo.slot = Battle.Combatants[Battle.IndexMap[target] or 0] or Battle.Combatants.LeftOther
	targetInfo.target = target
	targetInfo.isLeft = (targetInfo.target == 0 or targetInfo.target == 1)
	targetInfo.isOwner = (target % 2 == 0)

	return targetInfo
end
