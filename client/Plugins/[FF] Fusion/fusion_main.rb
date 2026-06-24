#================================================================================================
# Pokémon Fused Fates - Fusion System Main
#================================================================================================

module FusedPokemonConfig
  # The ID offset where the custom "Fused" species entries begin in PBS.
  # Formula: FUSION_START_ID + (head_num * MAX_SPECIES_COUNT) + body_num
  FUSION_START_ID = 1000

  # The maximum number of base species to reserve grid spacing for.
  MAX_SPECIES_COUNT = 1000
end

#====================================================================
# FusedPokemon Class
#====================================================================

class FusedPokemon < Pokemon
  attr_accessor :fused_head_id, :fused_body_id # Stores the species IDs for the head and body
  attr_accessor :is_fusion # Boolean flag

  # Move and Data Security: Store entire parent objects inside the fusion
  attr_accessor :parent_head_pokemon, :parent_body_pokemon

  # Initialization Method
  alias_method :fused_initialize, :initialize
  def initialize(species, level, player = $player, withMoves = true)
    @fused_head_id = nil
    @fused_body_id = nil
    @is_fusion = false
    @parent_head_pokemon = nil
    @parent_body_pokemon = nil
    fused_initialize(species, level, player, withMoves)
  end
end

#====================================================================
# Core Fusing Logic
#====================================================================

def pbFusePokemon(pkmn_head, pkmn_body)
  # Block fusion if either Pokemon is in a special form, an egg, or fainted
  if pkmn_head.form > 0 || pkmn_body.form > 0
    pbMessage(_INTL("Pokémon in special or temporary forms cannot be fused!"))
    return false
  elsif pkmn_head.egg? || pkmn_body.egg?
    pbMessage(_INTL("Pokémon Eggs cannot be fused!"))
    return false
  elsif pkmn_head.fainted? || pkmn_body.fainted?
    pbMessage(_INTL("Fainted Pokémon cannot be fused!"))
    return false
  end

  # Determine the new Fused species ID mathematically
  head_num = GameData::Species.keys.index(pkmn_head.species)
  body_num = GameData::Species.keys.index(pkmn_body.species)

  # Structural mapping for a unique fusion index
  fused_species_index = FusedPokemonConfig::FUSION_START_ID + (head_num * FusedPokemonConfig::MAX_SPECIES_COUNT) + body_num

  # Convert the Integer into a standard Symbol format (e.g., :FUSION_495517)
  fused_symbol = "FUSION_#{fused_species_index}".to_sym

  # Fallback safety validation if the mapped fusion entry is missing from the PBS data
  unless GameData::Species.try_get(fused_symbol)
    pbMessage(_INTL("These two Pokémon are not structurally compatible for fusion!"))
    return false
  end

  # Capture and calculate cross-generational attributes
  new_level = ((pkmn_head.level + pkmn_body.level) / 2).floor

  # Create the new fused entity
  fused_pkmn = FusedPokemon.new(fused_symbol, new_level)

  # Call the fusion scene and animation
  fusing_scene = PokemonFusing_Scene.new

  fusing_scene.pbStartScene(pkmn_head, pkmn_body)
  fusing_scene.pbStartFusionAnimation(pkmn_head, pkmn_body)
  fusing_scene.pbEndFusionAnimation(fused_pkmn)
  fusing_scene.pbEndScene

  # Clone and preserve full parental objects before changing anything
  fused_pkmn.parent_head_pokemon = pkmn_head.clone
  fused_pkmn.parent_body_pokemon = pkmn_body.clone

  # Ensure the cloned parent structures track their movesets perfectly
  fused_pkmn.parent_head_pokemon.moves = pkmn_head.moves.map { |m| m.clone }
  fused_pkmn.parent_body_pokemon.moves = pkmn_body.moves.map { |m| m.clone }

  # Write metadata heritage
  fused_pkmn.fused_head_id       = pkmn_head.species
  fused_pkmn.fused_body_id       = pkmn_body.species
  fused_pkmn.is_fusion           = true
  fused_pkmn.parent_body_pokemon = pkmn_body.clone
  fused_pkmn.parent_head_pokemon = pkmn_head.clone

  # OT Heritage: Ensure the Fused Pokemon obeys the body's original trainer
  fused_pkmn.owner = pkmn_body.owner.clone

  # Shiny Inheritance: If either parent is shiny, the fusion becomes shiny
  if pkmn_head.shiny? || pkmn_body.shiny?
    fused_pkmn.shiny = true
  end

  # Gender Matching: Inherits physical gender from the body component
  # Safety check: ensures the body's gender is valid for the new fused species' gender ratio
  species_data = GameData::Species.try_get(fused_symbol)
  if species_data.gender_ratio == :AlwaysMale
    fused_pkmn.gender = 0
  elsif species_data.gender_ratio == :AlwaysFemale
    fused_pkmn.gender = 1
  elsif species_data.gender_ratio == :Genderless
    fused_pkmn.gender = 2
  else
    # If the fused species allows both genders, respect the body's original gender
    fused_pkmn.gender = pkmn_body.gender
  end

  # Blend IVs and EVs (Averages, rounded down)
  GameData::Stat.each_main do |stat|
    fused_pkmn.iv[stat.id] = ((pkmn_body.iv[stat.id] + pkmn_head.iv[stat.id]) / 2).floor
    fused_pkmn.ev[stat.id] = ((pkmn_body.ev[stat.id] + pkmn_head.ev[stat.id]) / 2).floor
  end

  # Dynamic Ability Selection
  head_ability = pkmn_head.ability
  body_ability = pkmn_body.ability

  # Get the default base/hidden abilities assigned to the PBS entry of the fusion species
  fusion_base_abilities = species_data.abilities
  fusion_hidden_abilities = species_data.hidden_abilities
  default_fusion_ability = fusion_base_abilities[0] || fusion_hidden_abilities[0]

  if head_ability == body_ability
    # If both components share an ability, inherit it without a prompt
    fused_pkmn.ability = head_ability
  else
    # Build dynamic choice menu options
    options = []
    ability_map = []

    # Option for head's ability
    if head_ability && head_ability != body_ability
      head_name = GameData::Ability.get(head_ability).name
      options.push(_INTL("{1} (Head: {2})", head_name, pkmn_head.name))
      ability_map.push(head_ability)
    end

    # Option for body's ability
    if body_ability
      body_name = GameData::Ability.get(body_ability).name
      options.push(_INTL("{1} (Body: {2})", body_name, pkmn_body.name))
      ability_map.push(body_ability)
    end

    # Option for fusion's hidden ability if distinct
    if default_fusion_ability && !ability_map.include?(default_fusion_ability)
      fusion_ability_name = GameData::Ability.get(default_fusion_ability).name
      options.push(_INTL("{1} (Fusion Hidden)", fusion_ability_name))
      ability_map.push(default_fusion_ability)
    end

    # Prompt the choices through Essentials message UI
    pbMessage(_INTL("Choose an ability for the fused Pokémon."))
    choice = pbShowCommands(nil, options, 0)
    
    # Assign the chosen ability safely
    fused_pkmn.ability = ability_map[choice]
  end

  # Dynamic Nature Selection
  head_nature = pkmn_head.nature
  body_nature = pkmn_body.nature

  if head_nature == body_nature
    # If both components share a nature, inherit it without a prompt
    fused_pkmn.nature = head_nature
  else
    # Build dynamic choice menu options
    options = []
    nature_map = []

    # Option for head's nature
    if head_nature && head_nature != body_nature
      head_name = GameData::Nature.get(head_nature).name
      options.push(_INTL("{1} (Head: {2})", head_name, pkmn_head.name))
      nature_map.push(head_nature)
    end

    # Option for body's nature
    if body_nature
      body_name = GameData::Nature.get(body_nature).name
      options.push(_INTL("{1} (Body: {2})", body_name, pkmn_body.name))
      nature_map.push(body_nature)
    end

    # Prompt the choices through Essentials message UI
    pbMessage(_INTL("Choose a nature for the fused Pokémon."))
    choice = pbShowCommands(nil, options, 0)
        
    # Assign the chosen ability safely
    fused_pkmn.nature = nature_map[choice]
  end

  # Dynamic Movepool Merging
  combined_moves = []
  (pkmn_head.moves + pkmn_body.moves).each do |m|
    combined_moves.push(m.id) unless combined_moves.include?(m.id)
  end

  # Clear default moves generated by FusedPokemon.new
  fused_pkmn.forget_all_moves

  if combined_moves.length <= Pokemon::MAX_MOVES
    # Automatically teach all moves if they fit
    combined_moves.each { |move_id| fused_pkmn.learn_move(move_id) }
  else
    # Force player to choose 4 moves via native Relearn screen if pool overflows
    pbMessage(_INTL("The fused Pokémon has too many moves. Please choose which ones to keep."))
  
    # Temporarily teach the first 4, then open the menu using the full pool
    combined_moves[0...Pokemon::MAX_MOVES].each { |move_id| fused_pkmn.learn_move(move_id) }
  
    # Scene call for move teaching/relearning
    pbRelearnMoveScreen(fused_pkmn)
  end

  # Explicitly preserve item security - don't lose the head's item!
  if pkmn_head.hasItem?
    $bag.add(pkmn_head.item)
    pbMessage(_INTL("Returned {1}'s held item ({2}) to the Bag.", pkmn_head.name, GameData::Item.get(pkmn_head.item).name))
    pkmn_head.item = nil
  end

  # Recalculate everything with new values
  fused_pkmn.calc_stats

  # Update the player's party structure
  $player.party.delete(pkmn_head)
  index = $player.party.index(pkmn_body)
  $player.party[index] = fused_pkmn

  pbMessage(_INTL("The fusion was a success!"))
  return true
end

#====================================================================
# Core Unfusing Logic
#====================================================================

def pbUnfusePokemon(fused_pkmn)
  return false if fused_pkmn.nil? || !fused_pkmn.is_fusion

  if $player.party_full?
    pbMessage(_INTL("You need a free slot in your party to unfuse this Pokémon!"))
    return false
  end

  
  # Return any held item on the fusion to the bag before splitting
  if fused_pkmn.hasItem?
    $bag.add(fused_pkmn.item)
    pbMessage(_INTL("Returned the fusion's held item ({1}) to the Bag.", GameData::Item.get(fused_pkmn.item).name))
    fused_pkmn.item = nil
  end
  
  # Extract copies of original parents data structure
  head_pkmn = fused_pkmn.parent_head_pokemon
  body_pkmn = fused_pkmn.parent_body_pokemon

  # Emergency fallback if parent variables somehow got wiped
  if head_pkmn.nil? || body_pkmn.nil?
    head_pkmn = Pokemon.new(fused_pkmn.fused_head_id, fused_pkmn.level)
    body_pkmn = Pokemon.new(fused_pkmn.fused_body_id, fused_pkmn.level)
  end

  # EV Gains Handling: Distribute any EVs earned while fused back into the parents
  GameData::Stat.each_main do |stat|
    # Distribute the fusion's current EVs evenly back to parents
    body_pkmn.ev[stat.id] = (fused_pkmn.ev[stat.id] / 2).floor
    head_pkmn.ev[stat.id] = (fused_pkmn.ev[stat.id] / 2).floor
  end

  # Dynamic Level-Up Tracking: If the fusion leved up, both parents get the benefit
  if fused_pkmn.level > head_pkmn.level
    head_pkmn.level = fused_pkmn.level
    head_pkmn.calc_stats # Triggers automatic move updates or evolutions
  end

  if fused_pkmn.level > body_pkmn.level
    body_pkmn.level = fused_pkmn.level
    body_pkmn.calc_stats
  end

  head_pkmn.calc_stats
  body_pkmn.calc_stats

  # Replace the fusion in the party with the body, and append the head
  index = $player.party.index(fused_pkmn)
  $player.party[index] = body_pkmn
  $player.party.push(head_pkmn)

  pbMessage(_INTL("The fusion has been undone. {1} and {2} were separated!", body_pkmn.name, head_pkmn.name))
  return true
end