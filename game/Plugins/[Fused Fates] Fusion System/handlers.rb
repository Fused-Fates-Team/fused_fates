#================================================================================================
# Pokémon Fused Fates Fusion System - handlers
#================================================================================================

#================================================================
# module FusionHandlers
#================================================================
module FusionHandlers
  # Fuses two party Pokémon based on their given indexes
  # Default is index 0 (Head) and index 1 (Body)
  def self.fuse_party_pokemon(index1 = 0, index2 = 1)
    pkmn1 = $player.party[index1]
    pkmn2 = $player.party[index2]

    # Ensure both slots contain valid Pokémon
    unless pkmn1 && pkmn2
      pbMessage(_INTL("There aren't enough Pokémon to perform a fusion!"))
      return false
    end

    # Check if either Pokémon is an egg
    if pkmn1.egg? || pkmn2.egg?
      pbMessage(_INTL("Eggs cannot be fused!"))
      return false
    end

    # Check if either Pokémon is already a FusedPokemon (preventing multi-fusions)
    if pkmn1.is_a?(FusedPokemon) || pkmn2.is_a?(FusedPokemon) || (pkmn1.respond_to?(:fusion_head) && pkmn1.fusion_head) || (pkmn2.respond_to?(:fusion_head) && pkmn2.fusion_head)
     pbMessage(_INTL("Already-fused Pokémon cannot be fused again!"))
     return false
    end

    # Create deep copies of both original Pokémon for later restoration
    original_head_clone = pkmn1.clone
    original_body_clone = pkmn2.clone

    # Instantiate a new FusedPokemon taking the place of party slot 1
    fused_pkmn = FusedPokemon.new(pkmn1.species, pkmn1.level, true, true, pkmn1.species, pkmn2.species, original_head_clone, original_body_clone)
      
    # Store the actual original data clones inside accessor variables
    fused_pkmn.original_head_data = original_head_clone if fused_pkmn.respond_to?(:original_head_data=)
    fused_pkmn.original_body_data = original_body_clone if fused_pkmn.respond_to?(:original_body_data=)

    # TODO: Copy over essential stats/attributes
    # TODO: Bag and transfer held item
      
    $player.party[index1] = fused_pkmn
    pkmn1 = fused_pkmn

    # Recalculate stats
    fused_pkmn.calc_stats

    # Remove the second Pokémon from the party
    $player.party.delete_at(index2)

    pbMessage(_INTL("Successfully fused {1} and {2}!", pkmn1.name, pkmn2.name))
    return true
  end

  # Unfuse an existing FusedPokemon
  def self.unfuse_party_pokemon(index = 0)
    pkmn = $player.party[index]

    # Ensure slot contains a valid FusedPokemon
    unless pkmn.is_a?(FusedPokemon) && pkmn.respond_to?(:fusion_head) && pkmn.respond_to?(:fusion_body)
      pbMessage(_INTL("This Pokémon is not a fusion and cannot be unfused!"))
      return false
    end

    # Ensure the player has room in the party for the separated body Pokémon
    if $player.party.length >= Settings::MAX_PARTY_SIZE
      pbMessage(_INTL("Your party is full! You cannot unfuse this Pokémon."))
      return false
    end

    # Retrieve stored original clones if available, otherwise fallback to creating new ones
    if pkmn.respond_to?(:original_head_data) && pkmn.respond_to?(:original_body_data) && pkmn.original_head_data && pkmn.original_body_data
     original_head = pkmn.original_head_data
     original_body = pkmn.original_body_data
    else
     # Fallback safety if clones weren't stored
     original_head = Pokemon.new(pkmn.fusion_head, pkmn.level)
     original_body = Pokemon.new(pkmn.fusion_body, pkmn.level)
    end

    # Distribute experience gained during fusion between the two restored clones
    if pkmn.respond_to?(:exp) && original_head.respond_to?(:exp=) && original_body.respond_to?(:exp=)
      gained_exp = [0, pkmn.exp - (original_head.exp || 0)].max
      shared_exp_boost = gained_exp / 2
      
      original_head.exp += shared_exp_boost
      original_body.exp += shared_exp_boost
      
      # Refresh levels based on updated experience pools
      original_head.calc_stats if original_head.respond_to?(:calc_stats)
      original_body.calc_stats if original_body.respond_to?(:calc_stats)
    end

    head_name = original_head.name
    body_name = original_body.name

    # Replace the fused slot with the restored head Pokémon
    $player.party[index] = original_head

    # Push the restored body Pokémon to the end of the party
    $player.party.push(original_body)

    pbMessage(_INTL("Successfully unfused back into {1} and {2}!", head_name, body_name))
    return true
  end
end

#================================================================
# ItemHandlers
#================================================================
# TODO: Trigger a party selection screen