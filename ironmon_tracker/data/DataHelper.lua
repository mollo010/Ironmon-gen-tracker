DataHelper = {}

-- Searches for a Pokémon by name, finds the best match
function DataHelper.findPokemonId(name)
	if name == nil or name == "" then
		return PokemonData.BlankPokemon.pokemonID
	end

	-- Format list of Pokemon as id, name pairs
	local pokemonNames = {}
	for id, pokemon in ipairs(PokemonData.Pokemon) do
		pokemonNames[id] = pokemon.name:lower()
	end

	local id, _ = Utils.getClosestWord(name:lower(), pokemonNames, 3)
	return id or PokemonData.BlankPokemon.pokemonID
end

-- Searches for a Move by name, finds the best match
function DataHelper.findMoveId(name)
	if name == nil or name == "" then
		return tonumber(MoveData.BlankMove.id)
	end

	-- Format list of Moves as id, name pairs
	local moveNames = {}
	for id, move in ipairs(MoveData.Moves) do
		moveNames[id] = move.name:lower()
	end

	local id, _ = Utils.getClosestWord(name:lower(), moveNames, 3)
	return id or tonumber(MoveData.BlankMove.id)
end

-- Searches for an Ability by name, finds the best match
function DataHelper.findAbilityId(name)
	if name == nil or name == "" then
		return AbilityData.DefaultAbility.id
	end

	-- Format list of Abilities as id, name pairs
	local abilityNames = {}
	for id, ability in ipairs(AbilityData.Abilities) do
		abilityNames[id] = ability.name:lower()
	end

	local id, _ = Utils.getClosestWord(name:lower(), abilityNames, 3)
	return id or AbilityData.DefaultAbility.id
end

-- Searches for a Route by name, finds the best match
function DataHelper.findRouteId(name)
	if name == nil or name == "" then
		return RouteData.BlankRoute.id
	end

	-- Format list of Routes as id, name pairs
	local routeNames = {}
	for id, route in pairs(RouteData.Info) do
		if route.name ~= nil then
			routeNames[id] = route.name:lower()
		else
			routeNames[id] = "Unnamed Route"
		end
	end

	local id, _ = Utils.getClosestWord(name:lower(), routeNames, 3)
	return id or RouteData.BlankRoute.id
end

-- Returns a table with all of the important display data safely formatted to draw on screen.
-- forceView: optional, if true forces view as viewingOwn, otherwise forces enemy view
function DataHelper.buildTrackerScreenDisplay(forceView)
	local data = {}
	data.p = {} -- data about the Pokemon itself
	data.m = {} -- data about the Moves of the Pokemon
	data.x = {} -- misc data to display, such as heals, encounters, badges

	data.x.viewingOwn = Tracker.Data.isViewingOwn
	if forceView ~= nil then
		data.x.viewingOwn = forceView
	end

	--Assume we are always looking at the left pokemon on the opposing side for move effectiveness
	local viewedPokemon
	local opposingPokemon -- currently used exclusively for Low Kick weight calcs
	if data.x.viewingOwn then
		viewedPokemon = Battle.getViewedPokemon(true)
		opposingPokemon = Tracker.getPokemon(Battle.Combatants.LeftOther, false)
	else
		viewedPokemon = Battle.getViewedPokemon(false)
		opposingPokemon = Tracker.getPokemon(Battle.Combatants.LeftOwn, true)
	end

	if viewedPokemon == nil or viewedPokemon.pokemonID == 0 or not Program.isValidMapLocation() then
		viewedPokemon = Tracker.getDefaultPokemon()
	elseif not Tracker.Data.hasCheckedSummary then
		-- Don't display any spoilers about the stats/moves, but still show the pokemon icon, name, and level
		local defaultPokemon = Tracker.getDefaultPokemon()
		defaultPokemon.pokemonID = viewedPokemon.pokemonID
		defaultPokemon.level = viewedPokemon.level
		viewedPokemon = defaultPokemon
	end

	-- Add in Pokedex information about the Pokemon
	if PokemonData.isValid(viewedPokemon.pokemonID) then
		for key, value in pairs(PokemonData.Pokemon[viewedPokemon.pokemonID]) do
			viewedPokemon[key] = value
		end
	end

	-- POKEMON ITSELF (data.p)
	data.p.id = viewedPokemon.pokemonID
	data.p.name = viewedPokemon.name or Constants.BLANKLINE
	data.p.curHP = viewedPokemon.curHP or Constants.BLANKLINE
	data.p.level = viewedPokemon.level or Constants.BLANKLINE
	data.p.evo = viewedPokemon.evolution or Constants.BLANKLINE
	data.p.bst = viewedPokemon.bst or Constants.BLANKLINE
	data.p.lastlevel = Tracker.getLastLevelSeen(viewedPokemon.pokemonID) or ""
	data.p.status = MiscData.StatusCodeMap[viewedPokemon.status] or ""

	-- Add: Stats, Stages, and Nature
	data.p.nature = viewedPokemon.nature
	data.p.positivestat = ""
	data.p.negativestat = ""
	data.p.stages = {}
	for _, statKey in ipairs(Constants.OrderedLists.STATSTAGES) do
		data.p[statKey] = viewedPokemon.stats[statKey] or Constants.BLANKLINE
		data.p.stages[statKey] = viewedPokemon.statStages[statKey] or 6

		local natureMultiplier = Utils.getNatureMultiplier(statKey, data.p.nature)
		if natureMultiplier == 1.1 then
			data.p.positivestat = statKey
		elseif natureMultiplier == 0.9 then
			data.p.negativestat = statKey
		end
	end
	data.p.stages.acc = viewedPokemon.statStages.acc or 6
	data.p.stages.eva = viewedPokemon.statStages.eva or 6

	-- Update: Pokemon Types
	if Battle.inBattle and (data.x.viewingOwn or not Battle.isGhost) then
		-- Update displayed types as typing changes (i.e. Color Change)
		data.p.types = Program.getPokemonTypes(data.x.viewingOwn, Battle.isViewingLeft)
	else
		data.p.types = { viewedPokemon.types[1], viewedPokemon.types[2], }
	end

	-- Update: Pokemon Evolution
	if data.x.viewingOwn and data.p.evo == PokemonData.Evolutions.FRIEND and viewedPokemon.friendship >= Program.friendshipRequired then
		data.p.evo = "SOON"
	end

	-- Update: Held Item and Ability area(s)
	data.p.line1 = Constants.BLANKLINE
	data.p.line2 = Constants.BLANKLINE
	if data.x.viewingOwn then
		if viewedPokemon.heldItem ~= nil and viewedPokemon.heldItem ~= 0 then
			data.p.line1 = MiscData.Items[viewedPokemon.heldItem]
		end
		local abilityId = PokemonData.getAbilityId(viewedPokemon.pokemonID, viewedPokemon.abilityNum)
		if abilityId ~= nil and abilityId ~= 0 then
			data.p.line2 = AbilityData.Abilities[abilityId].name
		end
	else
		local trackedAbilities = Tracker.getAbilities(viewedPokemon.pokemonID)
		if trackedAbilities[1].id ~= nil and trackedAbilities[1].id ~= 0 then
			data.p.line1 = AbilityData.Abilities[trackedAbilities[1].id].name .. " /"
			data.p.line2 = Constants.HIDDEN_INFO
		end
		if trackedAbilities[2].id ~= nil and trackedAbilities[2].id ~= 0 then
			data.p.line2 = AbilityData.Abilities[trackedAbilities[2].id].name
		end
	end

	-- Add: Move Header
	data.m.nextmoveheader, data.m.nextmovelevel, data.m.nextmovespacing = Utils.getMovesLearnedHeader(viewedPokemon.pokemonID, viewedPokemon.level)

	-- MOVES OF POKEMON (data.m)
	data.m.moves = { {}, {}, {}, {}, } -- four empty move placeholders

	local stars
	if data.x.viewingOwn then
		stars = { "", "", "", "" }
	else
		stars = Utils.calculateMoveStars(viewedPokemon.pokemonID, viewedPokemon.level)
	end

	local trackedMoves = Tracker.getMoves(viewedPokemon.pokemonID)
	for i = 1, 4, 1 do
		local moveToCopy = MoveData.BlankMove
		if data.x.viewingOwn then
			if viewedPokemon.moves[i] ~= nil and viewedPokemon.moves[i].id ~= 0 then
				moveToCopy = MoveData.Moves[viewedPokemon.moves[i].id]
			end
		elseif trackedMoves ~= nil then
			-- If the Pokemon doesn't belong to the player, pull move data from tracked data
			if trackedMoves[i] ~= nil and trackedMoves[i].id ~= 0 then
				moveToCopy = MoveData.Moves[trackedMoves[i].id]
			end
		end

		-- Add in Move data information about the Move
		data.m.moves[i] = {}
		for key, value in pairs(moveToCopy) do
			data.m.moves[i][key] = value
		end

		local move = data.m.moves[i]

		move.starred = stars[i] ~= nil and stars[i] ~= ""

		-- Update: Specific Moves
		if move.name == "Hidden Power" and data.x.viewingOwn then
			move.type = Tracker.getHiddenPowerType()
			move.category = MoveData.TypeToCategory[move.type]
		elseif Options["Calculate variable damage"] then
			if move.name == "Weather Ball" then
				move.type, move.power = Utils.calculateWeatherBall(move.type, move.power)
				move.category = MoveData.TypeToCategory[move.type]
			elseif move.name == "Low Kick" and Battle.inBattle and opposingPokemon ~= nil then
				local targetWeight
				if opposingPokemon.weight ~= nil then
					targetWeight = opposingPokemon.weight
				elseif PokemonData.Pokemon[opposingPokemon.pokemonID] ~= nil then
					targetWeight = PokemonData.Pokemon[opposingPokemon.pokemonID].weight
				else
					targetWeight = 0
				end
				move.power = Utils.calculateWeightBasedDamage(move.power, targetWeight)
			elseif data.x.viewingOwn then
				if move.name == "Flail" or move.name == "Reversal" then
					move.power = Utils.calculateLowHPBasedDamage(move.power, viewedPokemon.curHP, viewedPokemon.stats.hp)
				elseif move.name == "Eruption" or move.name == "Water Spout" then
					move.power = Utils.calculateHighHPBasedDamage(move.power, viewedPokemon.curHP, viewedPokemon.stats.hp)
				elseif move.name == "Return" or move.name == "Frustration" then
					move.power = Utils.calculateFriendshipBasedDamage(move.power, viewedPokemon.friendship)
				end
			end
		end

		-- Update: If STAB
		if Battle.inBattle then
			local ownTypes = Program.getPokemonTypes(data.x.viewingOwn, Battle.isViewingLeft)
			move.isstab = Utils.isSTAB(move, move.type, ownTypes)
		end

		if move.pp == "0" then
			move.pp = Constants.BLANKLINE
		end
		if move.power == "0" then
			move.power = Constants.BLANKLINE
		end
		if move.accuracy == "0" then
			move.accuracy = Constants.BLANKLINE
		end

		-- Update: Actual PP Values
		if move.name ~= MoveData.BlankMove.name then
			if data.x.viewingOwn then
				move.pp = viewedPokemon.moves[i].pp
			elseif Options["Count enemy PP usage"] then
				-- Interate over tracked moves, since we don't know the full move list
				for _, actualMove in pairs(viewedPokemon.moves) do
					if tonumber(actualMove.id) == tonumber(move.id) then
						move.pp = actualMove.pp
					end
				end
			end
		end

		-- Update: Check if info should be hidden
		move.showeffective = true
		if Battle.isGhost then
			-- If fighting a ghost, hide effectiveness
			move.showeffective = false
		elseif not Options["Reveal info if randomized"] then
			-- If move info is randomized and the user doesn't want to know about it, hide it
			if data.x.viewingOwn then
				-- Don't show effectiveness of the player's moves if the enemy types are unknown
				move.showeffective = not PokemonData.IsRand.pokemonTypes
			else
				if MoveData.IsRand.moveType then
					move.type = PokemonData.Types.UNKNOWN
					move.showeffective = false
				end
				if MoveData.IsRand.movePP and move.pp ~= Constants.BLANKLINE then
					move.pp = Constants.HIDDEN_INFO
				end
				if MoveData.IsRand.movePower and move.power ~= Constants.BLANKLINE then
					move.power = Constants.HIDDEN_INFO
				end
				if MoveData.IsRand.moveAccuracy and move.accuracy ~= Constants.BLANKLINE then
					move.accuracy = Constants.HIDDEN_INFO
				end
			end
		end
		move.showeffective = move.showeffective and Options["Show move effectiveness"] and Battle.inBattle

		-- Update: Calculate move effectiveness
		if move.showeffective then
			local enemyTypes = Program.getPokemonTypes(not data.x.viewingOwn, true)
			move.effectiveness = Utils.netEffectiveness(move, move.type, enemyTypes)
		else
			move.effectiveness = 1
		end
	end

	-- MISC DATA (data.x)
	data.x.healperc = math.min(9999, Tracker.Data.healingItems.healing or 0)
	data.x.healnum = math.min(99, Tracker.Data.healingItems.numHeals or 0)
	data.x.pcheals = Tracker.Data.centerHeals

	data.x.route = Constants.BLANKLINE
	if RouteData.hasRoute(Battle.CurrentRoute.mapId) then
		data.x.route = RouteData.Info[Battle.CurrentRoute.mapId].name or Constants.BLANKLINE
	end

	if Battle.inBattle then
		data.x.encounters = Tracker.getEncounters(viewedPokemon.pokemonID, Battle.isWildEncounter)
		if data.x.encounters > 999 then
			data.x.encounters = 999
		end
	else
		data.x.encounters = 0
	end

	return data
end

function DataHelper.buildPokemonInfoDisplay(pokemonID)
	local data = {}
	data.p = {} -- data about the Pokemon itself
	data.e = {} -- data about the Type Effectiveness of the Pokemon
	data.x = {} -- misc data to display, such as notes

	local pokemon
	if pokemonID == nil or not PokemonData.isValid(pokemonID) then
		pokemon = PokemonData.BlankPokemon
	else
		pokemon = PokemonData.Pokemon[pokemonID]
	end

	local ownPokemonId = Battle.getViewedPokemon(true).pokemonID -- used to determine if looking up your lead Pokémon

	data.p.id = pokemon.pokemonID or 0
	data.p.name = pokemon.name or Constants.BLANKLINE
	data.p.bst = pokemon.bst or Constants.BLANKLINE
	data.p.weight = pokemon.weight or Constants.BLANKLINE
	data.p.evo = Utils.getDetailedEvolutionsInfo(pokemon.evolution)

	-- Hide Pokemon types if player shouldn't know about them
	if not PokemonData.IsRand.pokemonTypes or Options["Reveal info if randomized"] or pokemon.pokemonID == ownPokemonId then
		data.p.types = { pokemon.types[1], pokemon.types[2] }
	else
		data.p.types = { PokemonData.Types.UNKNOWN, PokemonData.Types.UNKNOWN }
	end

	data.p.movelvls = {}
	local moveLevelsList = pokemon.movelvls[GameSettings.versiongroup]
	if moveLevelsList ~= nil and #moveLevelsList ~= 0 then
		for _, moveLv in ipairs(moveLevelsList) do
			table.insert(data.p.movelvls, moveLv)
		end
	end

	data.e = PokemonData.getEffectiveness(pokemon.pokemonID)

	data.x.note = Tracker.getNote(pokemon.pokemonID) or ""

	-- Used for highlighting which moves have already been learned, but only for the Pokémon actively being viewed
	local viewedPokemon = Battle.getViewedPokemon(true) or Tracker.getDefaultPokemon()
	if viewedPokemon.pokemonID == pokemon.pokemonID then
		data.x.viewedPokemonLevel = viewedPokemon.level
	else
		data.x.viewedPokemonLevel = 0
	end

	return data
end

function DataHelper.buildMoveInfoDisplay(moveId)
	local data = {}
	data.m = {} -- data about the Move itself
	data.x = {} -- misc data to display

	local move
	if moveId == nil or not MoveData.isValid(moveId) then
		move = MoveData.BlankMove
	else
		move = MoveData.Moves[moveId]
	end

	data.m.id = tostring(move.id) or 0
	data.m.name = move.name or Constants.BLANKLINE
	data.m.type = move.type or PokemonData.Types.UNKNOWN
	data.m.category = move.category or MoveData.Categories.NONE
	data.m.pp = move.pp or "0"
	data.m.power = move.power or "0"
	data.m.accuracy = move.accuracy or "0"
	data.m.iscontact = move.iscontact or false
	data.m.priority = move.priority or "0"
	data.m.summary = move.summary or Constants.BLANKLINE

	local ownPokemon = Battle.getViewedPokemon(true)
	local hideSomeInfo = not Options["Reveal info if randomized"] and not Utils.pokemonHasMove(ownPokemon, move.name)

	if moveId == 237 and Utils.pokemonHasMove(ownPokemon, "Hidden Power") then -- 237 = Hidden Power
		data.m.type = Tracker.getHiddenPowerType() or PokemonData.Types.UNKNOWN
		data.m.category = MoveData.TypeToCategory[data.m.type]
		data.x.ownHasHiddenPower = true
	end

	-- Don't reveal randomized move info for moves the player's current pokemon doesn't have
	if hideSomeInfo then
		if MoveData.IsRand.moveType then
			data.m.type = PokemonData.Types.UNKNOWN
			if data.m.category ~= MoveData.Categories.STATUS then
				data.m.category = Constants.HIDDEN_INFO
			end
		end
		if MoveData.IsRand.movePP then
			data.m.pp = Constants.HIDDEN_INFO
		end
		if MoveData.IsRand.movePower then
			data.m.power = Constants.HIDDEN_INFO
		end
		if MoveData.IsRand.moveAccuracy then
			data.m.accuracy = Constants.HIDDEN_INFO
		end
	end

	if data.m.pp == "0" then
		data.m.pp = Constants.BLANKLINE
	end
	if data.m.power == "0" then
		data.m.power = Constants.BLANKLINE
	end
	if data.m.accuracy == "0" then
		data.m.accuracy = Constants.BLANKLINE
	end

	return data
end

function DataHelper.buildAbilityInfoDisplay(abilityId)
	local data = {}
	data.a = {} -- data about the Ability itself
	data.x = {} -- misc data to display

	local ability
	if abilityId == nil or not AbilityData.isValid(abilityId) then
		ability = AbilityData.DefaultAbility
	else
		ability = AbilityData.Abilities[abilityId]
	end

	data.a.id = ability.id or 0
	data.a.name = ability.name or Constants.BLANKLINE
	data.a.description = ability.description or Constants.BLANKLINE
	data.a.descriptionEmerald = ability.descriptionEmerald or Constants.BLANKLINE

	data.x = nil -- Currently unused

	return data
end

function DataHelper.buildRouteInfoDisplay(routeId)
	local data = {}
	data.r = {} -- data about the Route itself
	data.x = {} -- misc data to display

	local route
	if routeId == nil or not RouteData.hasRoute(routeId) then
		route = RouteData.BlankRoute
	else
		route = RouteData.Info[routeId]
	end

	data.r.name = route.name or Constants.BLANKLINE

	return data
end