#================================================================================================
# Pokémon Fused Fates Fusion System - 004_Evolution.rb
#================================================================================================

#==================================================================
# class FusedPokemon < Pokemon
#==================================================================
class FusedPokemon
  # alias_method check_evolution_internal
  unless method_defined?(:vanilla_fusion_check_evolution_internal)
    alias_method :vanilla_fusion_check_evolution_internal, :check_evolution_internal
  end
  # check_evolution_internal
  def check_evolution_internal(&block)
    # Run the vanilla check first.
    vanilla_evo = vanilla_fusion_check_evolution_internal(&block)
    return vanilla_evo if vanilla_evo
    
    # Stop here if it is a standard, non-fused Pokémon
    return nil unless respond_to?(:fused?) && fused?

    # Iterate through the Head and Body
    [@fusion_head, @fusion_body].compact.each do |comp_species|
      comp_data = GameData::Species.try_get(comp_species)
      next unless comp_data && comp_data.evolutions
      
      comp_data.evolutions.each do |evo|
        # Evolutions are yielded as: pkmn, target_species, method, parameter
        ret = yield self, evo[0], evo[1], evo[2]
        return ret if ret # Return the new species ID immediately if successful
      end
    end
    
    return nil
  end
end

#================================================================
# GameData::Evolution
#================================================================
GameData::Evolution.register({
  :id            => :TradeSpecies,
  :parameter     => :Species,
  :on_trade_proc => proc { |pkmn, parameter, other_pkmn|
    next false if !other_pkmn
    
    # Check if the other Pokemon is holding an everstone
    has_everstone = other_pkmn.hasItem?(:EVERSTONE)
    
    # Check if the other Pokemon matches the required species, or contains it as a component
    match = (other_pkmn.species == parameter)
    match ||= (other_pkmn.respond_to?(:fusion_head) && other_pkmn.fusion_head == parameter)
    match ||= (other_pkmn.respond_to?(:fusion_body) && other_pkmn.fusion_body == parameter)

    next match && !has_everstone
  }
})