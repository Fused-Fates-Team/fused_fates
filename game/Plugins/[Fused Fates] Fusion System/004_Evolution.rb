#================================================================================================
# Pokémon Fused Fates Fusion System - 004_Evolution.rb
#================================================================================================

#==================================================================
# class FusedPokemon
#==================================================================
class FusedPokemon
  # alias_method check_evolution_internal
  unless method_defined?(:vanilla_check_evolution_internal)
    alias_method :vanilla_check_evolution_internal, :check_evolution_internal
  end
  
  # check_evolution_internal
  def check_evolution_internal(&block)
    return nil if @__evaluating_fusion_evo
    @__evaluating_fusion_evo = true

    current_head = respond_to?(:fusion_head) ? self.fusion_head : @fusion_head
    current_body = respond_to?(:fusion_body) ? self.fusion_body : @fusion_body

    begin
      # Fused Pokémon Logic
      if respond_to?(:fused?) && fused?
        valid_fusion_evo = nil
        
        # Check Head component evolution
        if current_head && !valid_fusion_evo
          head_data = GameData::Species.try_get(current_head)
          if head_data && head_data.evolutions
            head_data.evolutions.each do |evo|
              target_head, evo_method, evo_parameter = evo
              
              # Construct and validate the resulting fusion species symbol
              new_fusion_sym = :"#{target_head}_#{current_body}"
              next unless GameData::Species.exists?(new_fusion_sym)
              
              # Evaluate condition
              if block_given?
                ret = block.call(self, new_fusion_sym, evo_method, evo_parameter)
                next unless ret
              end
              
              valid_fusion_evo = new_fusion_sym
              break
            end
          end
        end
        
        # Check Body component evolution
        if current_body && !valid_fusion_evo
          body_data = GameData::Species.try_get(current_body)
          if body_data && body_data.evolutions
            body_data.evolutions.each do |evo|
              target_body, evo_method, evo_parameter = evo
              
              # Construct and validate the resulting fusion species symbol
              new_fusion_sym = :"#{current_head}_#{target_body}"
              next unless GameData::Species.exists?(new_fusion_sym)
              
              # Evaluate condition
              if block_given?
                ret = block.call(self, new_fusion_sym, evo_method, evo_parameter)
                next unless ret
              end
              
              valid_fusion_evo = new_fusion_sym
              break
            end
          end
        end
        
        return valid_fusion_evo if valid_fusion_evo
      end

      # Vanilla Fallback - For base species or pre-defined Fused-to-Fused evolutions in PBS
      return vanilla_check_evolution_internal(&block)

    ensure
      @__evaluating_fusion_evo = false
    end
  end

  # alias_method species=
  unless method_defined?(:vanilla_species)
    alias_method :vanilla_species, :species=
  end

  def species=(value)
    if value.to_s.include?('_') && respond_to?(:fused?) && fused?
      parts = value.to_s.split('_', 2)

      @fusion_head = parts[0].upcase.to_sym
      @fusion_body = parts[1].upcase.to_sym
      @_virtual_species_data = nil # Clear proxy cache so stats update

      vanilla_species(@species)
      return
    end

    # Pass-through for normal species changes
    vanilla_species(value)
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