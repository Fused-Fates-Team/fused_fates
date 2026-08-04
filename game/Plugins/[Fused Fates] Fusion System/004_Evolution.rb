#================================================================================================
# Pokémon Fused Fates Fusion System - 004_Evolution.rb
# ===============================================================================================

#==================================================================
# class FusedPokemon
#==================================================================
class FusedPokemon < Pokemon
  def check_evolution_internal(&block)
    # Check standard evolution path first via super
    standard_evo = super(&block)
    return standard_evo if standard_evo

    # Check fusion component evolution paths if fused
    return nil unless fused?

    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)

    [head_data, body_data].each do |comp_data|
      next unless comp_data && comp_data.respond_to?(:evolutions) && comp_data.evolutions
      
      comp_data.evolutions.each do |evo|
        next if evo[3] # Skip prevolutions
        
        if block_given?
          ret2 = yield evo[0], evo[1], evo[2]
          return ret2 if ret2
        end
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