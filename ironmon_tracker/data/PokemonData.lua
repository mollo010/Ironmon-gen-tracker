PokemonData = {
	totalPokemon = 151,
}

PokemonData.IsRand = {
	pokemonTypes = false,
	pokemonAbilities = false, -- Currently unused by the Tracker, as it never reveals this information by default

}

-- Enumerated constants that defines the various types a Pokémon and its Moves are
PokemonData.Types = {
	NORMAL = "normal",
	FIGHTING = "fighting",
	FLYING = "flying",
	POISON = "poison",
	GROUND = "ground",
	ROCK = "rock",
	BUG = "bug",
	GHOST = "ghost",
	STEEL = "steel",
	FIRE = "fire",
	WATER = "water",
	GRASS = "grass",
	ELECTRIC = "electric",
	PSYCHIC = "psychic",
	ICE = "ice",
	DRAGON = "dragon",
	DARK = "dark",
	-- FAIRY = "fairy", -- Currently unused. Expect this to be unused in Gen 1-5
	UNKNOWN = "unknown", -- For the move "Curse" in Gen 2-4
	EMPTY = "", -- No second type for this Pokémon or an empty field
}

-- Enumerated constants that defines various evolution possibilities
-- This enum does NOT include levels for evolution, only stones, friendship, no evolution, etc.
PokemonData.Evolutions = {
	NONE = Constants.BLANKLINE, -- This Pokémon does not evolve.
	LEVEL = "LEVEL", -- Unused directly, necessary as an info index
	FRIEND = "FRIEND", -- High friendship
	FRIEND_READY = "READY", -- High friendship, Pokémon has enough friendship to evolve
	STONES = "STONE", -- Various evolution stone items
	THUNDER = "THUNDER", -- Thunder stone item
	FIRE = "FIRE", -- Fire stone item
	WATER = "WATER", -- Water stone item
	MOON = "MOON", -- Moon stone item
	LEAF = "LEAF", -- Leaf stone item
	SUN = "SUN", -- Sun stone item
	LEAF_SUN = "LF/SN", -- Leaf or Sun stone items
	WATER30 = "30/WTR", -- Water stone item or at level 30
	WATER37 = "37/WTR", -- Water stone item or at level 37
}
-- Table of Evolution methods as a short or detailed list, each containing the evo method(s)
PokemonData.EvoMethods = {
	[PokemonData.Evolutions.NONE] = {
		short = { Constants.BLANKLINE, },
		detailed = { Constants.BLANKLINE, },
	},
	[PokemonData.Evolutions.LEVEL] = {
		short = { "Lv.%s", }, -- requires level parameter
		detailed = { "Level %s", }, -- requires level value
	},
	[PokemonData.Evolutions.FRIEND] = {
		short = { "Friend", },
		detailed = { "%s Friendship", }, -- requires friendship value
	},
	[PokemonData.Evolutions.STONES] = {
		short = { "Thunder", "Water", "Fire", "Sun", "Moon", },
		detailed = { "5 Diff. Stones", },
	},
	[PokemonData.Evolutions.THUNDER] = {
		short = { "Thunder", },
		detailed = { "Thunder Stone", },
	},
	[PokemonData.Evolutions.WATER] = {
		short = { "Water", },
		detailed = { "Water Stone", },
	},
	[PokemonData.Evolutions.FIRE] = {
		short = { "Fire", },
		detailed = { "Fire Stone", },
	},
	[PokemonData.Evolutions.LEAF] = {
		short = { "Leaf", },
		detailed = { "Leaf Stone", },
	},
	[PokemonData.Evolutions.SUN] = {
		short = { "Sun", },
		detailed = { "Sun Stone", },
	},
	[PokemonData.Evolutions.MOON] = {
		short = { "Moon", },
		detailed = { "Moon Stone", },
	},
	[PokemonData.Evolutions.LEAF_SUN] = {
		short = { "Leaf", "Sun", },
		detailed = { "Leaf Stone", "Sun Stone", },
	},
	[PokemonData.Evolutions.WATER30] = {
		short = { "Lv.30", "Water", },
		detailed = { "Level 30", "Water Stone", },
	},
	[PokemonData.Evolutions.WATER37] = {
		short = { "Lv.37", "Water", },
		detailed = { "Level 37", "Water Stone", },
	},
}

PokemonData.BlankPokemon = {
	pokemonID = 0,
	name = Constants.BLANKLINE,
	types = { PokemonData.Types.UNKNOWN, PokemonData.Types.EMPTY },
	abilities = { 0, 0 },
	evolution = PokemonData.Evolutions.NONE,
	bst = Constants.BLANKLINE,
	movelvls = { {}, {} },
	weight = 0.0,
}

function PokemonData.initialize()
	-- Reads the types and abilities for each Pokemon in the Pokedex
	-- If any data at all was randomized, read in full Pokemon data from memory
	if GameSettings.GEN ==2 then

		PokemonData.totalPokemon=251

	end


	PokemonData.UpdateBST()
	for pokemonID=1, PokemonData.totalPokemon, 1 do
		local pokemonData = PokemonData.Pokemon[pokemonID]


			local types = PokemonData.readPokemonTypesFromMemory(pokemonID)
			if types ~= nil then
				pokemonData.types = types
			end
		end

	if PokemonData.checkIfDataIsRandomized() then
		-- print("Randomized " .. Constants.Words.POKEMON .. " data detected, reading from game memory...")
		for pokemonID=1, PokemonData.totalPokemon, 1 do
			local pokemonData = PokemonData.Pokemon[pokemonID]

			if PokemonData.IsRand.pokemonTypes then
				local types = PokemonData.readPokemonTypesFromMemory(pokemonID)
				if types ~= nil then
					pokemonData.types = types
				end
			end
			if PokemonData.IsRand.pokemonAbilities then
				local abilities = PokemonData.readPokemonAbilitiesFromMemory(pokemonID)
				if abilities ~= nil then
					pokemonData.abilities = abilities
				end
			end
		end
		local datalog = Constants.BLANKLINE .. " New " .. Constants.Words.POKEMON .. " data loaded: "
		if PokemonData.IsRand.pokemonTypes then
			datalog = datalog .. "Types, "
		end
		if PokemonData.IsRand.pokemonAbilities then
			datalog = datalog .. "Abilities, "
		end
		-- print(datalog:sub(1, -3)) -- Remove trailing ", "
	end

	-- Add in pokemon IDs since they were never manually included in the past
	for id, pokemon in ipairs(PokemonData.Pokemon) do
		if pokemon.bst ~= Constants.BLANKLINE then -- Skip fake Pokemon
			pokemon.pokemonID = id
		end
	end
end

function PokemonData.readPokemonTypesFromMemory(pokemonID)
	local typesData=0
	if (GameSettings.GEN ==2 )then

		typesData = Memory.readword(GameSettings.gBaseStats + ((pokemonID-1) * 0x20) + 0x07)
	else

	if GameSettings.game ==1 and pokemonID==151 then

		 typesData = Memory.readword(GameSettings.MEw + 0x06)

	else

		 typesData = Memory.readword(GameSettings.gBaseStats + ((pokemonID-1) * 0x1C) + 0x06)
	end
	if typesData==0 then

	end
	local typeOne = Utils.getbits(typesData, 0, 8)
	local typeTwo = Utils.getbits(typesData, 8, 8)

	return {
		PokemonData.TypeIndexMap[typeOne],
		PokemonData.TypeIndexMap[typeTwo],
	}
end
end

function PokemonData.readPokemonAbilitiesFromMemory(pokemonID)
	local abilitiesData = Memory.readword(GameSettings.gBaseStats + (pokemonID * 0x1C) + 0x16)
	local abilityIdOne = Utils.getbits(abilitiesData, 0, 8)
	local abilityIdTwo = Utils.getbits(abilitiesData, 8, 8)

	return {
		Utils.inlineIf(abilityIdOne == 0, 0, abilityIdOne),
		Utils.inlineIf(abilityIdTwo == 0, 0, abilityIdTwo),
	}
end


function PokemonData.UpdateBST()

	if GameSettings.GEN==2 then
		for pokemonID=1, PokemonData.totalPokemon , 1 do
			local bst= 0


			for i=1, 6,1 do
				bst= bst+ Memory.readbyte(GameSettings.gBaseStats  +i +(pokemonID-1)* 32)
			end


			PokemonData.Pokemon[pokemonID]["bst"]=tostring(bst)

		end
	else

	for pokemonID=1, PokemonData.totalPokemon -1, 1 do
		local bst= 0
		for i=0, 4,1 do
			bst= bst+ Memory.readbyte(GameSettings.gBaseStats +1 +i +(pokemonID-1)* 0x1C)
		end


		PokemonData.Pokemon[pokemonID]["bst"]=tostring(bst)

	end
	if GameSettings.game ==2 then
		local bst= 0
		for i=0, 4,1 do
			bst= bst+ Memory.readbyte(GameSettings.gBaseStats +1 +i +(151-1)* 0x1C)
		end


		PokemonData.Pokemon[151]["bst"]=tostring(bst)

	else
		local bst= 0
		for i=0, 4,1 do
			bst= bst+ Memory.readbyte(GameSettings.MEw +1 +i )
		end


		PokemonData.Pokemon[151]["bst"]=tostring(bst)


	end
end
end





function PokemonData.checkIfDataIsRandomized()
	local areTypesRandomized = false
	local areAbilitiesRandomized = false
	local checkBST=false

	-- Check once if any data was randomized
	local types = PokemonData.readPokemonTypesFromMemory(1) -- Bulbasaur
	--local abilities = PokemonData.readPokemonAbilitiesFromMemory(1) -- Bulbasaur


	if types ~= nil then
		areTypesRandomized = types[1] ~= PokemonData.Types.GRASS or types[2] ~= PokemonData.Types.POISON
	end


	-- Check twice if any data was randomized (Randomizer does *not* force a change)
	if not areTypesRandomized or not areAbilitiesRandomized then
		types = PokemonData.readPokemonTypesFromMemory(131) -- Lapras


		if types ~= nil and (types[1] ~= PokemonData.Types.WATER or types[2] ~= PokemonData.Types.ICE) then
			areTypesRandomized = true
		end

	end

	PokemonData.IsRand.pokemonTypes = areTypesRandomized
	-- For now, read in all ability data since it's not stored in the PokemonData.Pokemon below
	areAbilitiesRandomized = true
	PokemonData.IsRand.pokemonAbilities = areAbilitiesRandomized

	return areTypesRandomized or areAbilitiesRandomized
end

function PokemonData.getAbilityId(pokemonID, abilityNum)
	if true then
		return 0
	end

	local pokemon = PokemonData.Pokemon[pokemonID]
	local abilityId = pokemon.abilities[abilityNum + 1] -- abilityNum stored from memory as [0 or 1]
	return abilityId
end

function PokemonData.isValid(pokemonID)
	return pokemonID ~= nil and pokemonID >= 1 and pokemonID <= PokemonData.totalPokemon
end

function PokemonData.isImageIDValid(pokemonID)
	--Eggs (412), Ghosts (413), and placeholder (0)
	return PokemonData.isValid(pokemonID) or pokemonID == 412 or pokemonID == 413 or pokemonID == 0
end

function PokemonData.getIdFromName(pokemonName)
	for id, pokemon in pairs(PokemonData.Pokemon) do
		if string.upper(pokemon.name) == pokemonName then
			return id
		end
	end

	return nil
end

function PokemonData.namesToList()
	local pokemonNames = {}
	for _, pokemon in ipairs(PokemonData.Pokemon) do
		if pokemon.bst ~= Constants.BLANKLINE then -- Skip fake Pokemon
			table.insert(pokemonNames, pokemon.name)
		end
	end
	return pokemonNames
end

-- Returns a table that contains the type weaknesses, resistances, and immunities for a Pokémon, listed as type-strings
function PokemonData.getEffectiveness(pokemonID)
	local effectiveness = {
		[0] = {},
		[0.25] = {},
		[0.5] = {},
		[1] = {},
		[2] = {},
		[4] = {},
	}

	if not PokemonData.isValid(pokemonID) then
		return effectiveness
	end

	local pokemon = PokemonData.Pokemon[pokemonID]

	for moveType, typeMultiplier in pairs(MoveData.TypeToEffectiveness) do
		local total = 1
		if typeMultiplier[pokemon.types[1]] ~= nil then
			total = total * typeMultiplier[pokemon.types[1]]
		end
		if pokemon.types[2] ~= pokemon.types[1] and typeMultiplier[pokemon.types[2]] ~= nil then
			total = total * typeMultiplier[pokemon.types[2]]
		end
		if effectiveness[total] ~= nil then
			table.insert(effectiveness[total], moveType)
		end
	end

	return effectiveness
end

PokemonData.TypeIndexMap = {
	[0x00] = PokemonData.Types.NORMAL,
	[0x01] = PokemonData.Types.FIGHTING,
	[0x02] = PokemonData.Types.FLYING,
	[0x03] = PokemonData.Types.POISON,
	[0x04] = PokemonData.Types.GROUND,
	[0x05] = PokemonData.Types.ROCK,
	[0x07] = PokemonData.Types.BUG,
	[0x08] = PokemonData.Types.GHOST,
	[0x14] = PokemonData.Types.FIRE,
	[0x15] = PokemonData.Types.WATER,
	[0x16] = PokemonData.Types.GRASS,
	[0x17] = PokemonData.Types.ELECTRIC,
	[0x18] = PokemonData.Types.PSYCHIC,
	[0x19] = PokemonData.Types.ICE,
	[0x1A] = PokemonData.Types.DRAGON,
	[0x1B] = PokemonData.Types.DARK;
}

--[[
Data for each Pokémon (Gen 3) - Sourced from Bulbapedia
Format for an entry:
	name: string -> Name of the Pokémon as it appears in game
	types: {string, string} -> Each Pokémon can have one or two types, using the PokemonData.Types enum to alias the strings
	evolution: string -> Displays the level, item, or other requirement a Pokémon needs to evolve
	bst: string -> A sum of the base stats of the Pokémon
	movelvls: {{integer list}, {integer list}} -> A pair of tables (1:RSE/2:FRLG) declaring the levels at which a Pokémon learns new moves or an empty list means it learns nothing
	weight: pokemon's weight in kg (mainly used for Low Kick calculations)
]]
PokemonData.Pokemon = {
	{
		name = "Bulbasaur",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = "16",
		bst = "318",
		movelvls = { {7,13,20,27,34,41,48} , {7 ,7 ,13 ,13 ,20 ,20 ,27 ,27 ,34 ,34 ,41 ,41 ,48 ,48 } } ,
		weight = 6.9
	},
	{
		name = "Ivysaur",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = "32",
		bst = "405",
		movelvls = { {7,13,22,30,38,46,54} , {7 ,13 ,22 ,30 ,38 ,46 ,54 } } ,
		weight = 13.0
	},
	{
		name = "Venusaur",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { {7,13,22,30,43,55,65} , {7 ,13 ,22 ,30 ,43 ,55 ,65 } } ,
		weight = 100.0
	},
	{
		name = "Charmander",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "309",
		movelvls = {{9,15,22,30,38,46} , {9 ,15 ,22 ,30 ,38 ,46 } } ,
		weight = 8.5
	},
	{
		name = "Charmeleon",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "36",
		bst = "405",
		movelvls = { {9,15,24,33,42,56} , {9 ,15 ,24 ,33 ,42 ,56 } } ,
		weight = 19.0
	},
	{
		name = "Charizard",
		types = { PokemonData.Types.FIRE, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "534",
		movelvls = {   {9,15,24,36,46,55} , {9 ,15 ,24 ,36 ,46 ,55 } } ,
		weight = 90.5
	},
	{
		name = "Squirtle",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "314",
		movelvls = {  {8,15,22,28,35,42} , {8 ,15 ,22 ,28 ,35 ,42 } } ,
		weight = 9.0
	},
	{
		name = "Wartortle",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "36",
		bst = "405",
		movelvls = {  {8,15,24,31,39,47} , {8 ,15 ,24 ,31 ,39 ,47 } } ,
		weight = 22.5
	},
	{
		name = "Blastoise",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "530",
		movelvls = {  {8,15,24,31,42,52} , {8 ,15 ,24 ,31 ,42 ,52 } } ,
		weight = 85.5
	},
	{
		name = "Caterpie",
		types = { PokemonData.Types.BUG, PokemonData.Types.EMPTY },
		evolution = "7",
		bst = "195",
		movelvls = { {} , { } } ,
		weight = 2.9
	},
	{
		name = "Metapod",
		types = { PokemonData.Types.BUG, PokemonData.Types.EMPTY },
		evolution = "10",
		bst = "205",
		movelvls = { {  } , {7 } } ,
		weight = 9.9
	},
	{
		name = "Butterfree",
		types = { PokemonData.Types.BUG, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "385",
		movelvls = {  {12,15,16,21,26,32} , {10 ,13 ,14 ,15 ,18 ,23 ,28 ,34 } } ,
		weight = 32.0
	},
	{
		name = "Weedle",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = "7",
		bst = "195",
		movelvls = { {} , { } } ,
		weight = 3.2
	},
	{
		name = "Kakuna",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = "10",
		bst = "205",
		movelvls = { {  } , { } } ,
		weight = 10.0
	},
	{
		name = "Beedrill",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "385",
		movelvls = {  {12,16,20,25,30,35} , {12 ,16 ,20 ,25 ,30 ,35 } } ,
		weight = 29.5
	},
	{
		name = "Pidgey",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = "18",
		bst = "251",
		movelvls = {  {12,19,28,36,44} , {5 ,12 ,19 ,28 ,36 ,44 } } ,
		weight = 1.8
	},
	{
		name = "Pidgeotto",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = "36",
		bst = "349",
		movelvls = {   {12,21,31,40,49} , {5 ,12 ,21 ,31 ,40 ,49 } } ,
		weight = 30.0
	},
	{
		name = "Pidgeot",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "469",
		movelvls = {  {12,21,31,44,54} , {5 ,12 ,21 ,31 ,44 ,54 } } ,
		weight = 39.5
	},
	{
		name = "Rattata",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = "20",
		bst = "253",
		movelvls = { { 7, 14,23,34 } , {7 ,14 ,23 ,34 } } ,
		weight = 3.5
	},
	{
		name = "Raticate",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "413",
		movelvls = { { 7, 14,27,41 } , {7 ,14 ,27 ,41 } } ,
		weight = 18.5
	},
	{
		name = "Spearow",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = "20",
		bst = "262",
		movelvls = { { 9, 15,22,29,36 } , {9 ,15 ,22 ,29 ,36 } } ,
		weight = 2.0
	},
	{
		name = "Fearow",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "442",
		movelvls = { { 9, 15,25,34,43 } , {9 ,15 ,25 ,34 ,43 } } ,
		weight = 38.0
	},
	{
		name = "Ekans",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = "22",
		bst = "288",
		movelvls = { { 10, 17,24,31,38 } , {10 ,17 ,24 ,31 ,38 } } ,
		weight = 6.9
	},
	{
		name = "Arbok",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "438",
		movelvls = { { 10,17,27,36,47 } , {10 ,17 ,27 ,36 ,47 } } ,
		weight = 65.0
	},
	{
		name = "Pikachu",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.THUNDER,
		bst = "300",
		movelvls = {  { 9, 16,26,33,43 } , {6 ,8 ,11 ,15 ,20 ,26 ,33 ,41 ,50 } } ,
		weight = 6.0
	},
	{
		name = "Raichu",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "475",
		movelvls = { {} , { } } ,
		weight = 30.0
	},
	{
		name = "Sandshrew",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = "22",
		bst = "300",
		movelvls = { {10,17,24,31,38} , {10 ,17 ,24 ,31 ,38 } } ,
		weight = 12.0
	},
	{
		name = "Sandslash",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { {10,17,27,36,47  } , {10 ,17 ,27 ,36 ,47 } } ,
		weight = 29.5
	},
	{
		name = "Nidoran",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "275",
		movelvls = { {14,21,29,36,43 } , {8 ,12 ,17 ,23 ,30 ,38 } } ,
		weight = 7.0
	},
	{
		name = "Nidorina",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.MOON,
		bst = "365",
		movelvls = { {14,23,32,41,50 } , {8 ,12 ,19 ,27 ,36 ,46 } } ,
		weight = 20.0
	},
	{
		name = "Nidoqueen",
		types = { PokemonData.Types.POISON, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "495",
		movelvls = { {14, 23 } , {8 ,12 ,23 } } ,
		weight = 60.0
	},
	{
		name = "Nidoran M",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "273",
		movelvls = { {14,21,29,36,43 } , {8 ,12 ,17 ,23 ,30 ,38 } } ,
		weight = 9.0
	},
	{
		name = "Nidorino",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.MOON,
		bst = "365",
		movelvls = { {14,23,32,41,50 } , {8 ,12 ,19 ,27 ,36 ,46 } } ,
		weight = 19.5
	},
	{
		name = "Nidoking",
		types = { PokemonData.Types.POISON, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "495",
		movelvls = { { 14,23 } , {8 ,12 ,23 } } ,
		weight = 62.0
	},
	{
		name = "Clefairy",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.MOON,
		bst = "323",
		movelvls = { { 13,18,24,31,39,48 } , {13 ,18 ,24 ,31 ,39 ,48 } } ,
		weight = 7.5
	},
	{
		name = "Clefable",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "473",
		movelvls = { {} , { } } ,
		weight = 40.0
	},
	{
		name = "Vulpix",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FIRE,
		bst = "299",
		movelvls = { { 16,21,28,35,42} , {16 ,21 ,28 ,35 ,42 } } ,
		weight = 9.9
	},
	{
		name = "Ninetales",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "505",
		movelvls = { {  } , { } } ,
		weight = 19.9
	},
	{
		name = "Jigglypuff",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.MOON,
		bst = "270",
		movelvls = { { 14,19,24,29,34,39 } , {9 ,14 ,19 ,24 ,29 ,34 ,39 } } ,
		weight = 5.5
	},
	{
		name = "Wigglytuff",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "425",
		movelvls = { {} , { } } ,
		weight = 12.0
	},
	{
		name = "Zubat",
		types = { PokemonData.Types.POISON, PokemonData.Types.FLYING },
		evolution = "22",
		bst = "245",
		movelvls = { { 10,15,21,29,36 } , {10 ,15 ,21 ,28 ,36 } } ,
		weight = 7.5
	},
	{
		name = "Golbat",
		types = { PokemonData.Types.POISON, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.FRIEND,
		bst = "455",
		movelvls = { { 10,15,21,32,43} , {10 ,15 ,21 ,32 ,43 } } ,
		weight = 55.0
	},
	{
		name = "Oddish",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = "21",
		bst = "320",
		movelvls = { { 15,17,19,24,33,46 } , {15 ,17 ,19 ,24 ,33 ,46 } } ,
		weight = 5.4
	},
	{
		name = "Gloom",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.LEAF,
		bst = "395",
		movelvls = { { 15,17,19,28,38,52} , {15 ,17 ,19 ,28 ,38 ,52 } } ,
		weight = 8.6
	},
	{
		name = "Vileplume",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "480",
		movelvls = { { 15,17,19 } , {15 ,17 ,19 } } ,
		weight = 18.6
	},
	{
		name = "Paras",
		types = { PokemonData.Types.BUG, PokemonData.Types.GRASS },
		evolution = "24",
		bst = "285",
		movelvls = { { 13,20,27,34,41 } , {13 ,20 ,27 ,34 ,41 } } ,
		weight = 5.4
	},
	{
		name = "Parasect",
		types = { PokemonData.Types.BUG, PokemonData.Types.GRASS },
		evolution = PokemonData.Evolutions.NONE,
		bst = "405",
		movelvls = { { 13,20,30,39,48} , {13 ,20 ,30 ,39 ,48 } } ,
		weight = 29.5
	},
	{
		name = "Venonat",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = "31",
		bst = "305",
		movelvls = { { 24,27,30,35,38,43 } , {11 ,19 ,22 ,27 ,30 ,35 ,38 ,43 } } ,
		weight = 30.0
	},
	{
		name = "Venomoth",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { {24,27,30,38,43,50 } , {22 ,27 ,30 ,38 ,43 ,50 } } ,
		weight = 12.5
	},
	{
		name = "Diglett",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = "26",
		bst = "265",
		movelvls = { { 15,19,24,31,40 } , {15 ,19 ,24 ,31 ,40 } } ,
		weight = 0.8
	},
	{
		name = "Dugtrio",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "405",
		movelvls = { { 15,19,42,35,47 } , {15 ,19 ,24 ,35 ,47 } } ,
		weight = 33.3
	},
	{
		name = "Meowth",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = "28",
		bst = "290",
		movelvls = { { 12,17,24,33,44} , {12 ,17 ,24 ,33 ,44 } } ,
		weight = 4.2
	},
	{
		name = "Persian",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "440",
		movelvls = { { 12,17,24,37,51 } , {12 ,17 ,24 ,37 ,51 } } ,
		weight = 32.0
	},
	{
		name = "Psyduck",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "33",
		bst = "320",
		movelvls = { {28,31,36,43,52 } , {28 ,31 ,36 ,43 ,52 } } ,
		weight = 19.6
	},
	{
		name = "Golduck",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 28,31,39,48,59 } , {28 ,31 ,39 ,48 ,59 } } ,
		weight = 76.6
	},
	{
		name = "Mankey",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = "28",
		bst = "305",
		movelvls = { { 15,21,27,33,39 } , {9 ,15 ,21 ,27 ,33 ,39 ,45 } } ,
		weight = 28.0
	},
	{
		name = "Primeape",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { { 15,21,27,37,46 } , {9 ,15 ,21 ,27 ,28 ,37 ,45 ,46 } } ,
		weight = 32.0
	},
	{
		name = "Growlithe",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FIRE,
		bst = "350",
		movelvls = { {18,23,30,39,50 } , {18 ,23 ,30 ,39 ,50 } } ,
		weight = 19.0
	},
	{
		name = "Arcanine",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "555",
		movelvls = { {  } , { } } ,
		weight = 155.0
	},
	{
		name = "Poliwag",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "25",
		bst = "300",
		movelvls = { {16,19,25,31,38,45} , {16 ,19 ,25 ,31 ,38 ,45 } } ,
		weight = 12.4
	},
	{
		name = "Poliwhirl",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.WATER37, -- Level 37 replaces trade evolution for Politoed
		bst = "385",
		movelvls = { { 7, 13, 19, 27, 35, 43, 51 } , {16 ,19 ,26 ,33 ,41 ,49 } } ,
		weight = 20.0
	},
	{
		name = "Poliwrath",
		types = { PokemonData.Types.WATER, PokemonData.Types.FIGHTING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { {16,19 } , {16 ,19 } } ,
		weight = 54.0
	},
	{
		name = "Abra",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "310",
		movelvls = { {} , { } } ,
		weight = 19.5
	},
	{
		name = "Kadabra",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = "37", -- Level 37 replaces trade evolution
		bst = "400",
		movelvls = { { 16,20,27,31,38,42 } , {16 ,20 ,27 ,31 ,38 ,42 } } ,
		weight = 56.5
	},
	{
		name = "Alakazam",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 16,20,27,31,38,42 } , {16 ,20 ,27 ,31 ,38 ,42 } } ,
		weight = 48.0
	},
	{
		name = "Machop",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = "28",
		bst = "305",
		movelvls = { { 20,25,32,39,46} , {20 ,25 ,32 ,39 ,46 } } ,
		weight = 19.5
	},
	{
		name = "Machoke",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = "37", -- Level 37 replaces trade evolution
		bst = "405",
		movelvls = { { 20,25,36,44,52} , {20 ,25 ,36 ,44 ,52 } } ,
		weight = 70.5
	},
	{
		name = "Machamp",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "505",
		movelvls = { { 20,25,36,44,52 } , {20 ,25 ,36 ,44 ,52 } } ,
		weight = 130.0
	},
	{
		name = "Bellsprout",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = "21",
		bst = "300",
		movelvls = { { 13,15,18,21,26,33,42} , {13 ,15 ,18 ,21 ,26 ,33 ,42 } } ,
		weight = 4.0
	},
	{
		name = "Weepinbell",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.LEAF,
		bst = "390",
		movelvls = { { 13,15,18,23,29,38,49 } , {13 ,15 ,18 ,23 ,29 ,38 ,49 } } ,
		weight = 6.4
	},
	{
		name = "Victreebel",
		types = { PokemonData.Types.GRASS, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "480",
		movelvls = { {13,15,18} , {13 ,15 ,18 } } ,
		weight = 15.5
	},
	{
		name = "Tentacool",
		types = { PokemonData.Types.WATER, PokemonData.Types.POISON },
		evolution = "30",
		bst = "335",
		movelvls = { { 7,13,18,22,27,33,40,48 } , {7 ,13 ,18 ,22 ,27 ,33 ,40 ,48 } } ,
		weight = 45.5
	},
	{
		name = "Tentacruel",
		types = { PokemonData.Types.WATER, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "515",
		movelvls = { { 13,18,22,27,35,43,50} , {7 ,13 ,18 ,22 ,27 ,35 ,43 ,50 } } ,
		weight = 55.0
	},
	{
		name = "Geodude",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = "25",
		bst = "300",
		movelvls = { { 11,16,21,26,31,36} , {11 ,16 ,21 ,26 ,31 ,36 } } ,
		weight = 20.0
	},
	{
		name = "Graveler",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = "37", -- Level 37 replaces trade evolution
		bst = "390",
		movelvls = { { 11,16,21,29,36,43 } , {11 ,16 ,21 ,29 ,36 ,43 } } ,
		weight = 105.0
	},
	{
		name = "Golem",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "485",
		movelvls = { { 11,16,21,29,36,43 } , {11 ,16 ,21 ,29 ,36 ,43 } } ,
		weight = 300.0
	},
	{
		name = "Ponyta",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "40",
		bst = "410",
		movelvls = { { 30,32,35,39,43,48 } , {30 ,32 ,35 ,39 ,43 ,48 } } ,
		weight = 30.0
	},
	{
		name = "Rapidash",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 30,32,35,39,47,55 } , {30 ,32 ,35 ,39 ,47 ,55 } } ,
		weight = 95.0
	},
	{
		name = "Slowpoke",
		types = { PokemonData.Types.WATER, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.WATER37, -- Water stone replaces trade evolution to Slowking
		bst = "315",
		movelvls = { { 18,22,27,33,40,48} , {18 ,22 ,27 ,33 ,40 ,48 } } ,
		weight = 36.0
	},
	{
		name = "Slowbro",
		types = { PokemonData.Types.WATER, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 19,22,27,33,37,44,55 } , {18 ,22 ,27 ,33 ,37 ,44 ,55 } } ,
		weight = 78.5
	},
	{
		name = "Magnemite",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.STEEL },
		evolution = "30",
		bst = "325",
		movelvls = { {21,25,29,35,41,47} , {21 ,25 ,29 ,35 ,41 ,47 } } ,
		weight = 6.0
	},
	{
		name = "Magneton",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.STEEL },
		evolution = PokemonData.Evolutions.NONE,
		bst = "465",
		movelvls = { { 21,25,29,38,46,54 } , {21 ,25 ,29 ,38 ,46 ,54 } } ,
		weight = 60.0
	},
	{
		name = "Farfetch'd",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "352",
		movelvls = { { 7,15,23,31,39 } , {7 ,15 ,23 ,31 ,39 } } ,
		weight = 15.0
	},
	{
		name = "Doduo",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = "31",
		bst = "310",
		movelvls = { { 20,24,30,36,40,44 } , {20 ,24 ,30 ,36 ,40 ,44 } } ,
		weight = 39.2
	},
	{
		name = "Dodrio",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "460",
		movelvls = { { 20,24,30,39,45,51} , {20 ,24 ,30 ,39 ,45 ,51 } } ,
		weight = 85.2
	},
	{
		name = "Seel",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "34",
		bst = "325",
		movelvls = { { 30,35,40,45,50 } , {30 ,35 ,40 ,45 ,50 } } ,
		weight = 90.0
	},
	{
		name = "Dewgong",
		types = { PokemonData.Types.WATER, PokemonData.Types.ICE },
		evolution = PokemonData.Evolutions.NONE,
		bst = "475",
		movelvls = { { 30,35,44,50,56} , {30 ,35 ,44 ,50 ,56 } } ,
		weight = 120.0
	},
	{
		name = "Grimer",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = "38",
		bst = "325",
		movelvls = { { 30,33,37,42,48,55 } , {30 ,33 ,37 ,42 ,48 ,55 } } ,
		weight = 30.0
	},
	{
		name = "Muk", -- PUMP SLOP
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { {30,33,37,45,53,60} , {30 ,33 ,37 ,45 ,53 ,60 } } ,
		weight = 30.0
	},
	{
		name = "Shellder",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.WATER,
		bst = "305",
		movelvls = { { 18,23,30,39,50 } , {18 ,23 ,30 ,39 ,50 } } ,
		weight = 4.0
	},
	{
		name = "Cloyster",
		types = { PokemonData.Types.WATER, PokemonData.Types.ICE },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 50 } , {50 } } ,
		weight = 132.5
	},
	{
		name = "Gastly",
		types = { PokemonData.Types.GHOST, PokemonData.Types.POISON },
		evolution = "25",
		bst = "310",
		movelvls = { { 27,35 } , {27 ,35 } } ,
		weight = 0.1
	},
	{
		name = "Haunter",
		types = { PokemonData.Types.GHOST, PokemonData.Types.POISON },
		evolution = "37", -- Level 37 replaces trade evolution
		bst = "405",
		movelvls = { { 29,38} , {29 ,38 } } ,
		weight = 0.1
	},
	{
		name = "Gengar",
		types = { PokemonData.Types.GHOST, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 29,38 } , {29 ,38 } } ,
		weight = 40.5
	},
	{
		name = "Onix",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = "30", -- Level 30 replaces trade evolution
		bst = "385",
		movelvls = { { 15,19,25,33,43 } , {15 ,19 ,25 ,33 ,43 } } ,
		weight = 210.0
	},
	{
		name = "Drowzee",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = "26",
		bst = "328",
		movelvls = { { 12,17,24,29,32,37 } , {12 ,17 ,24 ,29 ,32 ,37 } } ,
		weight = 32.4
	},
	{
		name = "Hypno",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "483",
		movelvls = { { 12,17,24,33,37,43} , {12 ,17 ,24 ,33 ,37 ,43 } } ,
		weight = 75.6
	},
	{
		name = "Krabby",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "28",
		bst = "325",
		movelvls = { {20,25,30,35,40 } , {20 ,25 ,30 ,35 ,40 } } ,
		weight = 6.5
	},
	{
		name = "Kingler",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "475",
		movelvls = { {20,25,34,42,49 } , {20 ,25 ,34 ,42 ,49 } } ,
		weight = 60.0
	},
	{
		name = "Voltorb",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "330",
		movelvls = { { 17,22,29,36,43} , {17 ,22 ,29 ,36 ,43 } } ,
		weight = 10.4
	},
	{
		name = "Electrode",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "480",
		movelvls = { { 17,22,29,40,50 } , {17 ,22 ,29 ,40 ,50 } } ,
		weight = 66.6
	},
	{
		name = "Exeggcute",
		types = { PokemonData.Types.GRASS, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.LEAF,
		bst = "325",
		movelvls = { { 25,28,32,37,42,48 } , {25 ,28 ,32 ,37 ,42 ,48 } } ,
		weight = 2.5
	},
	{
		name = "Exeggutor",
		types = { PokemonData.Types.GRASS, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "520",
		movelvls = { { 28} , {28 } } ,
		weight = 120.0
	},
	{
		name = "Cubone",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = "28",
		bst = "320",
		movelvls = { { 25,31,38,43,46 } , {10 ,13 ,18 ,25 ,31 ,38 ,43 ,46 } } ,
		weight = 6.5
	},
	{
		name = "Marowak",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "425",
		movelvls = { { 25,33,41,48,55 } , {10 ,13 ,18 ,25 ,33 ,41 ,48 ,55 } } ,
		weight = 45.0
	},
	{
		name = "Hitmonlee",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { { 33,38,43,48,53 } , {33 ,38 ,43 ,48 ,53 } } ,
		weight = 49.8
	},
	{
		name = "Hitmonchan",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { {33,38,43,48,53 } , {33 ,38 ,43 ,48 ,53 } } ,
		weight = 50.2
	},
	{
		name = "Lickitung",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "385",
		movelvls = { { 7,15,23,31,39 } , {7 ,15 ,23 ,31 ,39 } } ,
		weight = 65.5
	},
	{
		name = "Koffing",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = "35",
		bst = "340",
		movelvls = { { 32,37,40,45,48 } , {32 ,37 ,40 ,45 ,48 } } ,
		weight = 1.0
	},
	{
		name = "Weezing",
		types = { PokemonData.Types.POISON, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 32,39,43,49,53} , {32 ,39 ,43 ,49 ,53 } } ,
		weight = 9.5
	},
	{
		name = "Rhyhorn",
		types = { PokemonData.Types.GROUND, PokemonData.Types.ROCK },
		evolution = "42",
		bst = "345",
		movelvls = { { 30,35,40,45,50,55 } , {30 ,35 ,40 ,45 ,50 ,55 } } ,
		weight = 115.0
	},
	{
		name = "Rhydon",
		types = { PokemonData.Types.GROUND, PokemonData.Types.ROCK },
		evolution = PokemonData.Evolutions.NONE,
		bst = "485",
		movelvls = { { 30,35,40,45,50,55} , {30 ,35 ,40 ,48 ,55 ,64 } } ,
		weight = 120.0
	},
	{
		name = "Chansey",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { { 24,30,38,44,48,54 } , {12 ,24 ,30 ,38 ,44 ,48 ,54 } } ,
		weight = 34.6
	},
	{
		name = "Tangela",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "435",
		movelvls = { { 29,32,36,39,45,49 } , {24 ,27 ,29 ,32 ,36 ,39 ,45 ,48 } } ,
		weight = 35.0
	},
	{
		name = "Kangaskhan",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 26,31,36,41,46 } , {26 ,31 ,36 ,41 ,46 } } ,
		weight = 80.0
	},
	{
		name = "Horsea",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "32",
		bst = "295",
		movelvls = { { 19,24,30,37,45 } , {19 ,24 ,30 ,37 ,45 } } ,
		weight = 8.0
	},
	{
		name = "Seadra",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "40", -- Level 40 replaces trade evolution
		bst = "440",
		movelvls = { {19,224,30,41,52 } , {19 ,24 ,30 ,41 ,52 } } ,
		weight = 25.0
	},
	{
		name = "Goldeen",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "33",
		bst = "320",
		movelvls = { { 19,24,30,37,45,54 } , {19 ,24 ,30 ,37 ,45 ,54 } } ,
		weight = 15.0
	},
	{
		name = "Seaking",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { { 19,24,30,39,48,54 } , {19 ,24 ,30 ,39 ,48 ,54 } } ,
		weight = 39.0
	},
	{
		name = "Staryu",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.WATER,
		bst = "340",
		movelvls = { {17,22,27,32,37,42,47 } , {17 ,22 ,27 ,32 ,37 ,42 ,47 } } ,
		weight = 34.5
	},
	{
		name = "Starmie",
		types = { PokemonData.Types.WATER, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "520",
		movelvls = { {  } , { } } ,
		weight = 80.0
	},
	{
		name = "Mr.Mime",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "460",
		movelvls = { { 15,23,31,39,47 } , {15 ,23 ,31 ,39 ,47 } } ,
		weight = 54.5
	},
	{
		name = "Scyther",
		types = { PokemonData.Types.BUG, PokemonData.Types.FLYING },
		evolution = "30", -- Level 30 replaces trade evolution
		bst = "500",
		movelvls = { { 17,20,24,29,35,42 } , {17 ,20 ,24 ,29 ,35 ,42 ,50 } } ,
		weight = 56.0
	},
	{
		name = "Jynx",
		types = { PokemonData.Types.ICE, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { { 18,23,31,39,47,58 } , {18 ,23 ,31 ,39 ,47 ,58 } } ,
		weight = 40.6
	},
	{
		name = "Electabuzz",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 34,37,42,49,54 } , {34 ,37 ,42 ,49 ,54 } } ,
		weight = 30.0
	},
	{
		name = "Magmar", -- MAMGAR
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "495",
		movelvls = { { 36,39,43,48,52,55 } , {36 ,39 ,43 ,48 ,52 ,55 } } ,
		weight = 44.5
	},
	{
		name = "Pinsir",
		types = { PokemonData.Types.BUG, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 25,30,36,43,49,54 } , {21 ,25 ,30 ,36 ,43 ,49 ,54 } } ,
		weight = 55.0
	},
	{
		name = "Tauros",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 21,28,35,44,51 } , {21 ,28 ,35 ,44 ,51 } } ,
		weight = 88.4
	},
	{
		name = "Magikarp",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "20",
		bst = "200",
		movelvls = { { 15 } , {15 } } ,
		weight = 10.0
	},
	{
		name = "Gyarados",
		types = { PokemonData.Types.WATER, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "540",
		movelvls = { { 22,25,32,41,52} , {20 ,25 ,32 ,41 ,52 } } ,
		weight = 235.0
	},
	{
		name = "Lapras",
		types = { PokemonData.Types.WATER, PokemonData.Types.ICE },
		evolution = PokemonData.Evolutions.NONE,
		bst = "535",
		movelvls = { { 16,20,25,31,38,46 } , {16 ,20 ,25 ,31 ,38 ,46 } } ,
		weight = 220.0
	},
	{
		name = "Ditto",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "288",
		movelvls = { {} , { } } ,
		weight = 4.0
	},
	{
		name = "Eevee",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.STONES,
		bst = "325",
		movelvls = { { 27,31,37,45 } , {8 ,16 ,23 ,30 ,36 ,42 } } ,
		weight = 6.5
	},
	{
		name = "Vaporeon",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 27,31,37,40,42,44,48,54} , {8 ,16 ,23 ,30 ,36 ,42 ,42 ,47 ,52 } } ,
		weight = 29.0
	},
	{
		name = "Jolteon",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 27,31,37,40,42,44,48,54} , {8 ,16 ,23 ,30 ,36 ,42 ,47 ,52 } } ,
		weight = 24.5
	},
	{
		name = "Flareon",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 27,31,37,40,42,44,48,54} , {8 ,16 ,23 ,30 ,36 ,42 ,47 ,52 } } ,
		weight = 25.0
	},
	{
		name = "Porygon",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE, -- Level 30 replaces trade evolution
		bst = "395",
		movelvls = { { 23,28,35,42} , {23 ,28 ,35 ,42 } } ,
		weight = 36.5
	},
	{
		name = "Omanyte",
		types = { PokemonData.Types.ROCK, PokemonData.Types.WATER },
		evolution = "40",
		bst = "355",
		movelvls = { { 34,39,46,53 } , {34 ,39 ,46 ,53 } } ,
		weight = 7.5
	},
	{
		name = "Omastar", -- LORD HELIX
		types = { PokemonData.Types.ROCK, PokemonData.Types.WATER },
		evolution = PokemonData.Evolutions.NONE,
		bst = "495",
		movelvls = { { 34,39,44,49 } , {34 ,39 ,44 ,49 } } ,
		weight = 35.0
	},
	{
		name = "Kabuto",
		types = { PokemonData.Types.ROCK, PokemonData.Types.WATER },
		evolution = "40",
		bst = "355",
		movelvls = { { 34,39,44,49 } , {34 ,39 ,44 ,49 } } ,
		weight = 11.5
	},
	{
		name = "Kabutops",
		types = { PokemonData.Types.ROCK, PokemonData.Types.WATER },
		evolution = PokemonData.Evolutions.NONE,
		bst = "495",
		movelvls = { { 34,39,46,53 } , {34 ,39 ,46 ,53 } } ,
		weight = 40.5
	},
	{
		name = "Aerodactyl",
		types = { PokemonData.Types.ROCK, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "515",
		movelvls = { { 33,38,45,54 } , {33 ,38 ,45 ,54 } } ,
		weight = 59.0
	},
	{
		name = "Snorlax",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "540",
		movelvls = { { 35,41,48,56 } , {35 ,41 ,48 ,56 } } ,
		weight = 460.0
	},
	{
		name = "Articuno",
		types = { PokemonData.Types.ICE, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = { { 51,55,60 } , {51 ,55 ,60 } } ,
		weight = 55.4
	},
	{
		name = "Zapdos",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = {  { 51,55,60 } , {51 ,55 ,60 } } ,
		weight = 52.6
	},
	{
		name = "Moltres",
		types = { PokemonData.Types.FIRE, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = {  { 51,55,60 } , {51 ,55 ,60 } } ,
		weight = 60.0
	},
	{
		name = "Dratini",
		types = { PokemonData.Types.DRAGON, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "300",
		movelvls = { { 10,20,30,40,50 } , {10 ,20 ,30 ,40 ,50 } } ,
		weight = 3.3
	},
	{
		name = "Dragonair",
		types = { PokemonData.Types.DRAGON, PokemonData.Types.EMPTY },
		evolution = "55",
		bst = "420",
		movelvls = { { 10,20,35,45,55} , {10 ,20 ,35 ,45 ,55 } } ,
		weight = 16.5
	},
	{
		name = "Dragonite",
		types = { PokemonData.Types.DRAGON, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "600",
		movelvls = { { 18,20,35,45,60 } , {10 ,20 ,35 ,45 ,60 } } ,
		weight = 210.0
	},
	{
		name = "Mewtwo",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "680",
		movelvls = { { 63,66,70,75,81} , {63 ,66 ,70 ,75 ,81 } } ,
		weight = 122.0
	},
	{
		name = "Mew",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "600",
		movelvls = { { 10, 20, 30, 40, 50 }, { 10, 20, 30, 40, 50 } },
		weight = 4.0
	},
	{
		name = "Chikorita",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = "16",
		bst = "318",
		movelvls = { { 8, 12, 15, 22, 29, 36, 43, 50 }, { 8, 12, 15, 22, 29, 36, 43, 50 } },
		weight = 6.4
	},
	{
		name = "Bayleef",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = "32",
		bst = "405",
		movelvls = { { 8, 12, 15, 23, 31, 39, 47, 55 }, { 8, 12, 15, 23, 31, 39, 47, 55 } },
		weight = 15.8
	},
	{
		name = "Meganium",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 8, 12, 15, 23, 31, 41, 51, 61 }, { 8, 12, 15, 23, 31, 41, 51, 61 } },
		weight = 100.5
	},
	{
		name = "Cyndaquil",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "14",
		bst = "309",
		movelvls = { { 6, 12, 19, 27, 36, 46 }, { 6, 12, 19, 27, 36, 46 } },
		weight = 7.9
	},
	{
		name = "Quilava",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "36",
		bst = "405",
		movelvls = { { 6, 12, 21, 31, 42, 54 }, { 6, 12, 21, 31, 42, 54 } },
		weight = 19.0
	},
	{
		name = "Typhlosion",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "534",
		movelvls = { { 6, 12, 21, 31, 45, 60 }, { 6, 12, 21, 31, 45, 60 } },
		weight = 79.5
	},
	{
		name = "Totodile",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "18",
		bst = "314",
		movelvls = { { 7, 13, 20, 27, 35, 43, 52 }, { 7, 13, 20, 27, 35, 43, 52 } },
		weight = 9.5
	},
	{
		name = "Croconaw",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "405",
		movelvls = { { 7, 13, 21, 28, 37, 45, 55 }, { 7, 13, 21, 28, 37, 45, 55 } },
		weight = 25.0
	},
	{
		name = "Feraligatr",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "530",
		movelvls = { { 7, 13, 21, 28, 38, 47, 58 }, { 7, 13, 21, 28, 38, 47, 58 } },
		weight = 88.8
	},
	{
		name = "Sentret",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = "15",
		bst = "215",
		movelvls = { { 4, 7, 12, 17, 24, 31, 40, 49 }, { 4, 7, 12, 17, 24, 31, 40, 49 } },
		weight = 6.0
	},
	{
		name = "Furret",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "415",
		movelvls = { { 4, 7, 12, 19, 28, 37, 48, 59 }, { 4, 7, 12, 19, 28, 37, 48, 59 } },
		weight = 32.5
	},
	{
		name = "Hoothoot",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = "20",
		bst = "262",
		movelvls = { { 6, 11, 16, 22, 28, 34, 48 }, { 6, 11, 16, 22, 28, 34, 48 } },
		weight = 21.2
	},
	{
		name = "Noctowl",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "442",
		movelvls = { { 6, 11, 16, 25, 33, 41, 57 }, { 6, 11, 16, 25, 33, 41, 57 } },
		weight = 40.8
	},
	{
		name = "Ledyba",
		types = { PokemonData.Types.BUG, PokemonData.Types.FLYING },
		evolution = "18",
		bst = "265",
		movelvls = { { 8, 15, 22, 22, 22, 29, 36, 43, 50 }, { 8, 15, 22, 22, 22, 29, 36, 43, 50 } },
		weight = 10.8
	},
	{
		name = "Ledian",
		types = { PokemonData.Types.BUG, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "390",
		movelvls = { { 8, 15, 24, 24, 24, 33, 42, 51, 60 }, { 8, 15, 24, 24, 24, 33, 42, 51, 60 } },
		weight = 35.6
	},
	{
		name = "Spinarak",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = "22",
		bst = "250",
		movelvls = { { 6, 11, 17, 23, 30, 37, 45, 53 }, { 6, 11, 17, 23, 30, 37, 45, 53 } },
		weight = 8.5
	},
	{
		name = "Ariados",
		types = { PokemonData.Types.BUG, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "390",
		movelvls = { { 6, 11, 17, 25, 34, 43, 53, 63 }, { 6, 11, 17, 25, 34, 43, 53, 63 } },
		weight = 33.5
	},
	{
		name = "Crobat",
		types = { PokemonData.Types.POISON, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "535",
		movelvls = { { 6, 11, 16, 21, 28, 35, 42, 49, 56 }, { 6, 11, 16, 21, 28, 35, 42, 49, 56 } },
		weight = 75.0
	},
	{
		name = "Chinchou",
		types = { PokemonData.Types.WATER, PokemonData.Types.ELECTRIC },
		evolution = "27",
		bst = "330",
		movelvls = { { 5, 13, 17, 25, 29, 37, 41, 49 }, { 5, 13, 17, 25, 29, 37, 41, 49 } },
		weight = 12.0
	},
	{
		name = "Lanturn",
		types = { PokemonData.Types.WATER, PokemonData.Types.ELECTRIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "460",
		movelvls = { { 5, 13, 17, 25, 32, 43, 50, 61 }, { 5, 13, 17, 25, 32, 43, 50, 61 } },
		weight = 22.5
	},
	{
		name = "Pichu",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FRIEND,
		bst = "205",
		movelvls = { { 6, 8, 11 }, { 6, 8, 11 } },
		weight = 2.0
	},
	{
		name = "Cleffa",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FRIEND,
		bst = "218",
		movelvls = { { 4, 8, 13 }, { 4, 8, 13, 17 } },
		weight = 3.0
	},
	{
		name = "Igglybuff",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FRIEND,
		bst = "210",
		movelvls = { { 4, 9, 14 }, { 4, 9, 14 } },
		weight = 1.0
	},
	{
		name = "Togepi",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.FRIEND,
		bst = "245",
		movelvls = { { 6, 11, 16, 21, 26, 31, 36, 41 }, { 4, 9, 13, 17, 21, 25, 29, 33, 37, 41 } },
		weight = 1.5
	},
	{
		name = "Togetic",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "405",
		movelvls = { { 6, 11, 16, 21, 26, 31, 36, 41 }, { 4, 9, 13, 17, 21, 25, 29, 33, 37, 41 } },
		weight = 3.2
	},
	{
		name = "Natu",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.FLYING },
		evolution = "25",
		bst = "320",
		movelvls = { { 10, 20, 30, 30, 40, 50 }, { 10, 20, 30, 30, 40, 50 } },
		weight = 2.0
	},
	{
		name = "Xatu",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "470",
		movelvls = { { 10, 20, 35, 35, 50, 65 }, { 10, 20, 35, 35, 50, 65 } },
		weight = 15.0
	},
	{
		name = "Mareep",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = "15",
		bst = "280",
		movelvls = { { 9, 16, 23, 30, 37 }, { 9, 16, 23, 30, 37 } },
		weight = 7.8
	},
	{
		name = "Flaaffy",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "365",
		movelvls = { { 9, 18, 27, 36, 45 }, { 9, 18, 27, 36, 45 } },
		weight = 13.3
	},
	{
		name = "Ampharos",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 9, 18, 27, 30, 42, 57 }, { 9, 18, 27, 30, 42, 57 } },
		weight = 61.5
	},
	{
		name = "Bellossom",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "480",
		movelvls = { { 44, 55 }, { 44, 55 } },
		weight = 5.8
	},
	{
		name = "Marill",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "18",
		bst = "250",
		movelvls = { { 3, 6, 10, 15, 21, 28, 36, 45 }, { 3, 6, 10, 15, 21, 28, 36, 45 } },
		weight = 8.5
	},
	{
		name = "Azumarill",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "410",
		movelvls = { { 3, 6, 10, 15, 24, 34, 45, 57 }, { 3, 6, 10, 15, 24, 34, 45, 57 } },
		weight = 28.5
	},
	{
		name = "Sudowoodo",
		types = { PokemonData.Types.ROCK, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "410",
		movelvls = { { 9, 17, 25, 33, 41, 49, 57 }, { 9, 17, 25, 33, 41, 49, 57 } },
		weight = 38.0
	},
	{
		name = "Politoed",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 35, 51 }, { 35, 51 } },
		weight = 33.9
	},
	{
		name = "Hoppip",
		types = { PokemonData.Types.GRASS, PokemonData.Types.FLYING },
		evolution = "18",
		bst = "250",
		movelvls = { { 5, 5, 10, 13, 15, 17, 20, 25, 30 }, { 5, 5, 10, 13, 15, 17, 20, 25, 30 } },
		weight = 0.5
	},
	{
		name = "Skiploom",
		types = { PokemonData.Types.GRASS, PokemonData.Types.FLYING },
		evolution = "27",
		bst = "340",
		movelvls = { { 5, 5, 10, 13, 15, 17, 22, 29, 36 }, { 5, 5, 10, 13, 15, 17, 22, 29, 36 } },
		weight = 1.0
	},
	{
		name = "Jumpluff",
		types = { PokemonData.Types.GRASS, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { { 5, 5, 10, 13, 15, 17, 22, 33, 44 }, { 5, 5, 10, 13, 15, 17, 22, 33, 44 } },
		weight = 3.0
	},
	{
		name = "Aipom",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "360",
		movelvls = { { 6, 13, 18, 25, 31, 38, 43, 50 }, { 6, 13, 18, 25, 31, 38, 43, 50 } },
		weight = 11.5
	},
	{
		name = "Sunkern",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.SUN,
		bst = "180",
		movelvls = { { 6, 13, 18, 25, 30, 37, 42 }, { 6, 13, 18, 25, 30, 37, 42 } },
		weight = 1.8
	},
	{
		name = "Sunflora",
		types = { PokemonData.Types.GRASS, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "425",
		movelvls = { { 6, 13, 18, 25, 30, 37, 42 }, { 6, 13, 18, 25, 30, 37, 42 } },
		weight = 8.5
	},
	{
		name = "Yanma",
		types = { PokemonData.Types.BUG, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "390",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 6, 12, 17, 23, 28, 34, 39, 45, 50 } },
		weight = 38.0
	},
	{
		name = "Wooper",
		types = { PokemonData.Types.WATER, PokemonData.Types.GROUND },
		evolution = "20",
		bst = "210",
		movelvls = { { 11, 16, 21, 31, 36, 41, 51, 51 }, { 11, 16, 21, 31, 36, 41, 51, 51 } },
		weight = 8.5
	},
	{
		name = "Quagsire",
		types = { PokemonData.Types.WATER, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "430",
		movelvls = { { 11, 16, 23, 35, 42, 49, 61, 61 }, { 11, 16, 23, 35, 42, 49, 61, 61 } },
		weight = 75.0
	},
	{
		name = "Espeon",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 8, 16, 23, 30, 36, 42, 47, 52 }, { 8, 16, 23, 30, 36, 42, 47, 52 } },
		weight = 26.5
	},
	{
		name = "Umbreon",
		types = { PokemonData.Types.DARK, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "525",
		movelvls = { { 8, 16, 23, 30, 36, 42, 47, 52 }, { 8, 16, 23, 30, 36, 42, 47, 52 } },
		weight = 27.0
	},
	{
		name = "Murkrow",
		types = { PokemonData.Types.DARK, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "405",
		movelvls = { { 9, 14, 22, 27, 35, 40, 48 }, { 9, 14, 22, 27, 35, 40, 48 } },
		weight = 2.1
	},
	{
		name = "Slowking",
		types = { PokemonData.Types.WATER, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 6, 15, 20, 29, 34, 43, 48 }, { 6, 13, 17, 24, 29, 36, 40, 47 } },
		weight = 79.5
	},
	{
		name = "Misdreavus",
		types = { PokemonData.Types.GHOST, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "435",
		movelvls = { { 6, 11, 17, 23, 30, 37, 45, 53 }, { 6, 11, 17, 23, 30, 37, 45, 53 } },
		weight = 1.0
	},
	{
		name = "Unown",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "336",
		movelvls = { {}, {} },
		weight = 5.0
	},
	{
		name = "Wobbuffet",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "405",
		movelvls = { {}, {} },
		weight = 28.5
	},
	{
		name = "Girafarig",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.PSYCHIC },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 13, 19, 25, 31, 37, 43, 49 } },
		weight = 41.5
	},
	{
		name = "Pineco",
		types = { PokemonData.Types.BUG, PokemonData.Types.EMPTY },
		evolution = "31",
		bst = "290",
		movelvls = { { 8, 15, 22, 29, 36, 43, 50 }, { 8, 15, 22, 29, 36, 43, 50 } },
		weight = 7.2
	},
	{
		name = "Forretress",
		types = { PokemonData.Types.BUG, PokemonData.Types.STEEL },
		evolution = PokemonData.Evolutions.NONE,
		bst = "465",
		movelvls = { { 8, 15, 22, 29, 39, 49, 59 }, { 8, 15, 22, 29, 31, 39, 49, 59 } },
		weight = 125.8
	},
	{
		name = "Dunsparce",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "415",
		movelvls = { { 4, 11, 14, 21, 24, 31, 34, 41 }, { 4, 11, 14, 21, 24, 31, 34, 41, 44, 51 } },
		weight = 14.0
	},
	{
		name = "Gligar",
		types = { PokemonData.Types.GROUND, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "430",
		movelvls = { { 6, 13, 20, 28, 36, 44, 52 }, { 6, 13, 20, 28, 36, 44, 52 } },
		weight = 64.8
	},
	{
		name = "Steelix",
		types = { PokemonData.Types.STEEL, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "510",
		movelvls = { { 9, 13, 21, 25, 33, 37, 45, 49, 57 }, { 8, 12, 19, 23, 30, 34, 41, 45, 52, 56 } },
		weight = 400.0
	},
	{
		name = "Snubbull",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = "23",
		bst = "300",
		movelvls = { { 4, 8, 13, 19, 26, 34, 43, 53 }, { 4, 8, 13, 19, 26, 34, 43, 53 } },
		weight = 7.8
	},
	{
		name = "Granbull",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { { 4, 8, 13, 19, 28, 38, 49, 61 }, { 4, 8, 13, 19, 28, 38, 49, 61 } },
		weight = 48.7
	},
	{
		name = "Qwilfish",
		types = { PokemonData.Types.WATER, PokemonData.Types.POISON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "430",
		movelvls = { { 10, 10, 19, 28, 37, 46 }, { 9, 9, 13, 21, 25, 33, 37, 45 } },
		weight = 3.9
	},
	{
		name = "Scizor",
		types = { PokemonData.Types.BUG, PokemonData.Types.STEEL },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 6, 11, 16, 21, 26, 31, 36, 41, 46 }, { 6, 11, 16, 21, 26, 31, 36, 41, 46 } },
		weight = 118.0
	},
	{
		name = "Shuckle",
		types = { PokemonData.Types.BUG, PokemonData.Types.ROCK },
		evolution = PokemonData.Evolutions.NONE,
		bst = "505",
		movelvls = { { 9, 14, 23, 28, 37 }, { 9, 14, 23, 28, 37 } },
		weight = 20.5
	},
	{
		name = "Heracross",
		types = { PokemonData.Types.BUG, PokemonData.Types.FIGHTING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 6, 11, 17, 23, 30, 37, 45, 53 }, { 6, 11, 17, 23, 30, 37, 45, 53 } },
		weight = 54.0
	},
	{
		name = "Sneasel",
		types = { PokemonData.Types.DARK, PokemonData.Types.ICE },
		evolution = PokemonData.Evolutions.NONE,
		bst = "430",
		movelvls = { { 8, 15, 22, 29, 36, 43, 50, 57, 64 }, { 8, 15, 22, 29, 36, 43, 50, 57, 64 } },
		weight = 28.0
	},
	{
		name = "Teddiursa",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "330",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 13, 19, 25, 31, 37, 43, 49 } },
		weight = 8.8
	},
	{
		name = "Ursaring",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 13, 19, 25, 31, 37, 43, 49 } },
		weight = 125.8
	},
	{
		name = "Slugma",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "38",
		bst = "250",
		movelvls = { { 8, 15, 22, 29, 36, 43, 50 }, { 8, 15, 22, 29, 36, 43, 50 } },
		weight = 35.0
	},
	{
		name = "Magcargo",
		types = { PokemonData.Types.FIRE, PokemonData.Types.ROCK },
		evolution = PokemonData.Evolutions.NONE,
		bst = "410",
		movelvls = { { 8, 15, 22, 29, 36, 48, 60 }, { 8, 15, 22, 29, 36, 48, 60 } },
		weight = 55.0
	},
	{
		name = "Swinub",
		types = { PokemonData.Types.ICE, PokemonData.Types.GROUND },
		evolution = "33",
		bst = "250",
		movelvls = { { 10, 19, 28, 37, 46, 55 }, { 10, 19, 28, 37, 46, 55 } },
		weight = 6.5
	},
	{
		name = "Piloswine",
		types = { PokemonData.Types.ICE, PokemonData.Types.GROUND },
		evolution = PokemonData.Evolutions.NONE,
		bst = "450",
		movelvls = { { 10, 19, 28, 33, 42, 56, 70 }, { 10, 19, 28, 33, 42, 56, 70 } },
		weight = 55.8
	},
	{
		name = "Corsola",
		types = { PokemonData.Types.WATER, PokemonData.Types.ROCK },
		evolution = PokemonData.Evolutions.NONE,
		bst = "380",
		movelvls = { { 6, 12, 17, 17, 23, 28, 34, 39, 45 }, { 6, 12, 17, 17, 23, 28, 34, 39, 45 } },
		weight = 5.0
	},
	{
		name = "Remoraid",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = "25",
		bst = "300",
		movelvls = { { 11, 22, 22, 22, 33, 44, 55 }, { 11, 22, 22, 22, 33, 44, 55 } },
		weight = 12.0
	},
	{
		name = "Octillery",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "480",
		movelvls = { { 11, 22, 22, 22, 25, 38, 54, 70 }, { 11, 22, 22, 22, 25, 38, 54, 70 } },
		weight = 28.5
	},
	{
		name = "Delibird",
		types = { PokemonData.Types.ICE, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "330",
		movelvls = { {}, {} },
		weight = 16.0
	},
	{
		name = "Mantine",
		types = { PokemonData.Types.WATER, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "465",
		movelvls = { { 8, 15, 22, 29, 36, 43, 50 }, { 8, 15, 22, 29, 36, 43, 50 } },
		weight = 220.0
	},
	{
		name = "Skarmory",
		types = { PokemonData.Types.STEEL, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "465",
		movelvls = { { 10, 13, 16, 26, 29, 32, 42, 45 }, { 10, 13, 16, 26, 29, 32, 42, 45 } },
		weight = 50.5
	},
	{
		name = "Houndour",
		types = { PokemonData.Types.DARK, PokemonData.Types.FIRE },
		evolution = "24",
		bst = "330",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 13, 19, 25, 31, 37, 43, 49 } },
		weight = 10.8
	},
	{
		name = "Houndoom",
		types = { PokemonData.Types.DARK, PokemonData.Types.FIRE },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 7, 13, 19, 27, 35, 43, 51, 59 }, { 7, 13, 19, 27, 35, 43, 51, 59 } },
		weight = 35.0
	},
	{
		name = "Kingdra",
		types = { PokemonData.Types.WATER, PokemonData.Types.DRAGON },
		evolution = PokemonData.Evolutions.NONE,
		bst = "540",
		movelvls = { { 8, 15, 22, 29, 40, 51, 62 }, { 8, 15, 22, 29, 40, 51, 62 } },
		weight = 152.0
	},
	{
		name = "Phanpy",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = "25",
		bst = "330",
		movelvls = { { 9, 17, 25, 33, 41, 49 }, { 9, 17, 25, 33, 41, 49 } },
		weight = 33.5
	},
	{
		name = "Donphan",
		types = { PokemonData.Types.GROUND, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "500",
		movelvls = { { 9, 17, 25, 33, 41, 49 }, { 9, 17, 25, 33, 41, 49 } },
		weight = 120.0
	},
	{
		name = "Porygon2",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "515",
		movelvls = { { 9, 12, 20, 24, 32, 36, 44, 48 }, { 9, 12, 20, 24, 32, 36, 44, 48 } },
		weight = 32.5
	},
	{
		name = "Stantler",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "465",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 11, 17, 21, 27, 31, 37, 41, 47 } },
		weight = 71.2
	},
	{
		name = "Smeargle",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "250",
		movelvls = { { 11, 21, 31, 41, 51, 61, 71, 81, 91 }, { 11, 21, 31, 41, 51, 61, 71, 81, 91 } },
		weight = 58.0
	},
	{
		name = "Tyrogue",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = "20",
		bst = "210",
		movelvls = { {}, {} },
		weight = 21.0
	},
	{
		name = "Hitmontop",
		types = { PokemonData.Types.FIGHTING, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "455",
		movelvls = { { 7, 13, 19, 20, 25, 31, 37, 43, 49 }, { 7, 13, 19, 20, 25, 31, 37, 43, 49 } },
		weight = 48.0
	},
	{
		name = "Smoochum",
		types = { PokemonData.Types.ICE, PokemonData.Types.PSYCHIC },
		evolution = "30",
		bst = "305",
		movelvls = { { 9, 13, 21, 25, 33, 37, 45, 49, 57 }, { 9, 13, 21, 25, 33, 37, 45, 49, 57 } },
		weight = 6.0
	},
	{
		name = "Elekid",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "360",
		movelvls = { { 9, 17, 25, 33, 41, 49 }, { 9, 17, 25, 33, 41, 49 } },
		weight = 23.5
	},
	{
		name = "Magby",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = "30",
		bst = "365",
		movelvls = { { 7, 13, 19, 25, 31, 37, 43, 49 }, { 7, 13, 19, 25, 31, 37, 43, 49 } },
		weight = 21.4
	},
	{
		name = "Miltank",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "490",
		movelvls = { { 4, 8, 13, 19, 26, 34, 43, 53 }, { 4, 8, 13, 19, 26, 34, 43, 53 } },
		weight = 75.5
	},
	{
		name = "Blissey",
		types = { PokemonData.Types.NORMAL, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "540",
		movelvls = { { 4, 7, 10, 13, 18, 23, 28, 33, 40, 47 }, { 4, 7, 10, 13, 18, 23, 28, 33, 40, 47 } },
		weight = 46.8
	},
	{
		name = "Raikou",
		types = { PokemonData.Types.ELECTRIC, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = { { 11, 21, 31, 41, 51, 61, 71, 81 }, { 11, 21, 31, 41, 51, 61, 71, 81 } },
		weight = 178.0
	},
	{
		name = "Entei",
		types = { PokemonData.Types.FIRE, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = { { 11, 21, 31, 41, 51, 61, 71, 81 }, { 11, 21, 31, 41, 51, 61, 71, 81 } },
		weight = 198.0
	},
	{
		name = "Suicune",
		types = { PokemonData.Types.WATER, PokemonData.Types.EMPTY },
		evolution = PokemonData.Evolutions.NONE,
		bst = "580",
		movelvls = { { 11, 21, 31, 41, 51, 61, 71, 81 }, { 11, 21, 31, 41, 51, 61, 71, 81 } },
		weight = 187.0
	},
	{
		name = "Larvitar",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = "30",
		bst = "300",
		movelvls = { { 8, 15, 22, 29, 36, 43, 50, 57 }, { 8, 15, 22, 29, 36, 43, 50, 57 } },
		weight = 72.0
	},
	{
		name = "Pupitar",
		types = { PokemonData.Types.ROCK, PokemonData.Types.GROUND },
		evolution = "55",
		bst = "410",
		movelvls = { { 8, 15, 22, 29, 38, 47, 56, 65 }, { 8, 15, 22, 29, 38, 47, 56, 65 } },
		weight = 152.0
	},
	{
		name = "Tyranitar",
		types = { PokemonData.Types.ROCK, PokemonData.Types.DARK },
		evolution = PokemonData.Evolutions.NONE,
		bst = "600",
		movelvls = { { 8, 15, 22, 29, 38, 47, 61, 75 }, { 8, 15, 22, 29, 38, 47, 61, 75 } },
		weight = 202.0
	},
	{
		name = "Lugia",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "680",
		movelvls = { { 11, 22, 33, 44, 55, 66, 77, 88, 99 }, { 11, 22, 33, 44, 55, 66, 77, 88, 99 } },
		weight = 216.0
	},
	{
		name = "Ho-Oh",
		types = { PokemonData.Types.FIRE, PokemonData.Types.FLYING },
		evolution = PokemonData.Evolutions.NONE,
		bst = "680",
		movelvls = { { 11, 22, 33, 44, 55, 66, 77, 88, 99 }, { 11, 22, 33, 44, 55, 66, 77, 88, 99 } },
		weight = 199.0
	},
	{
		name = "Celebi",
		types = { PokemonData.Types.PSYCHIC, PokemonData.Types.GRASS },
		evolution = PokemonData.Evolutions.NONE,
		bst = "600",
		movelvls = { { 10, 20, 30, 40, 50 }, { 10, 20, 30, 40, 50 } },
		weight = 5.0
	},
}
