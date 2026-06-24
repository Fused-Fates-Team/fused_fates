#================================================================================================
# Pokémon Fused Fates - Fusion System Evolutions
#================================================================================================

module GameData
  class Species
    def self.break_down_fusion_symbol
      return nil unless symbol.to_s.start_with?("FUSION_")
      
      fusion_index = symbol.to_s.split("_")[1].to_i
      relative_id = fusion_index - FusedPokemonConfig::FUSION_START_ID

      head_num = (relative_id / FusedPokemonConfig::MAX_SPECIES_COUNT).floor
      body_num = relative_id % FusedPokemonConfig::MAX_SPECIES_COUNT

      # Filter out FUSION entries from the keys array
      # to reconstruct the true sequential list of base species.
      base_species_list = GameData::Species.keys.reject { |k| k.to_s.start_with?("FUSION_") }

      head_species = base_species_list[head_num]
      body_species = base_species_list[body_num]

      return [head_species, body_species]
    end
  end
end

#====================================================================
# FusedPokemon Class
#====================================================================

class FusedPokemon < Pokemon
  alias_method :fused_check_evolution, :check_evolution_internal

  def check_evolution_internal
    # Fusion Check
    new_species = fused_check_evolution
    if new_species && self.respond_to?(:is_fusion) && self.is_fusion
      process_fusion_evolution(new_species)
    end

    return new_species
  end

  private

  def process_fusion_evolution(new_fused_symbol)
    return unless GameData::Species.exists?(new_fused_symbol)

    new_components = GameData::Species.break_down_fusion_symbol(new_fused_symbol)
    return if new_components.nil?

    new_head_species, new_body_species = new_components

    # Evolve the internal parent snapshot objects first
    if self.fused_head_id != new_head_species && self.parent_head_pokemon
      pbForceParentEvolution(self.parent_head_pokemon, new_head_species)
    end

    if self.fused_body_id != new_body_species && self.parent_body_pokemon
      pbForceParentEvolution(self.parent_body_pokemon, new_body_species)
    end

    # Update the wrapper tracking IDs safely inside the method scope
    self.fused_head_id = new_head_species
    self.fused_body_id = new_body_species
  end

  def pbForceParentEvolution(parent_pkmn, target_species)
    parent_pkmn.species = target_species
    parent_pkmn.calc_stats

    # Ensure the parent is not flagged as ready to evolve
    # to prevent double-triggering or loops
    parent_pkmn.ready_to_evolve = false
    
    # Trigger move learning for the new evolution stage
    GameData::Species.get(target_species).moves.each do |m|
      if m[0] == parent_pkmn.level
        parent_pkmn.learn_move(m[1])
      end
    end
  end
end