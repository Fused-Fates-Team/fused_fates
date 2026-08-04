#================================================================================================
# Pokémon Fused Fates Fusion System - 003_ItemHandlers.rb
#================================================================================================

#==================================================================
# ItemHandlers
#==================================================================
ItemHandlers::UseOnPokemon.add(:DNASPLICERS, proc { |item, qty, pkmn, scene|
  # Safely resolve pkmn whether an index integer or a Pokemon object was passed
  pkmn1_index = -1
  if pkmn.is_a?(Numeric)
    pkmn1_index = pkmn
    pkmn = $player.party[pkmn1_index]
  else
    pkmn1_index = $player.party.index(pkmn)
    if pkmn1_index.nil?
      $player.party.each_with_index do |p, i|
        if p && p.personalID == pkmn.personalID
          pkmn1_index = i
          break
        end
      end
    end
  end

  # Explicit Index Bounds Checking
  if !pkmn || pkmn1_index < 0 || pkmn1_index >= $player.party.length
    scene.pbDisplay(_INTL("The DNA Splicers couldn't be used."))
    next false
  end

  # Check if already fused (Unfuse branch)
  if pkmn.respond_to?(:fused?) && pkmn.fused?
    if FusionHandlers.respond_to?(:unfuse_party_pokemon) && FusionHandlers.unfuse_party_pokemon(pkmn1_index)
      scene.pbHardRefresh
      next true 
    else
      scene.pbDisplay(_INTL("This Pokémon cannot be unfused right now."))
      next false
    end
  end

  # Choose the second Pokémon (Fuse branch)
  if !scene.respond_to?(:pbChoosePokemon)
    next false
  end

  # Prompt the scene for the second Pokémon
  chosen_index = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
  
  # Handle UI responses (nil, -1, or Array [action, index])
  if chosen_index.nil? || (chosen_index.is_a?(Numeric) && chosen_index < 0) || (chosen_index.is_a?(Array) && chosen_index[1] < 0)
    scene.pbRefresh
    next false
  end

  # Extract actual index if an array was returned by the party screen
  chosen_index = chosen_index[1] if chosen_index.is_a?(Array)

  # Validate and Execute Fusion
  if chosen_index != pkmn1_index
    chosen_pkmn = $player.party[chosen_index]
    
    if chosen_pkmn && !chosen_pkmn.egg? && (!chosen_pkmn.respond_to?(:fused?) || !chosen_pkmn.fused?)
      if FusionHandlers.respond_to?(:fuse_party_pokemon) && FusionHandlers.fuse_party_pokemon(pkmn1_index, chosen_index)
        scene.pbHardRefresh
        next true # Successful fusion
      else
        scene.pbDisplay(_INTL("Fusion failed!"))
        next false
      end
    else
      scene.pbDisplay(_INTL("That Pokémon cannot be fused!"))
      next false
    end
  else
    scene.pbDisplay(_INTL("You can't fuse a Pokémon with itself!"))
    next false
  end
})