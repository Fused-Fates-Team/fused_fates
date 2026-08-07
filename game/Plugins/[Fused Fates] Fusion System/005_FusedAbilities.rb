#================================================================================================
# Pokémon Fused Fates Fusion System - 005_Abilities.rb
#================================================================================================

#==================================================================
# module FusedAbilities
#==================================================================
module FusedAbilities
  @combo_registry = {}
  @equivalent_abilities = {}

  # Abilities which are too volatile to fuse at all
  @blacklisted_singles = [:WONDERGUARD, :SHADOWTAG, :ARENATRAP]

  # Specific pairs that create broken syngergies
  @blacklisted_pairs = [
    [:HUGEPOWER, :PUREPOWER],
    [:PROTEAN, :LIBERO],
    [:MAGICGUARD, :UNAWARE]
  ]

  def self.combo_registry
    @combo_registry
  end

  # Register custom pairs of different abilities that share the exact same effects
  def self.register_equivalent_ability(id1, id2)
    @equivalent_abilities[id1] ||= []
    @equivalent_abilities[id1] << id2 unless @equivalent_abilities[id1].include?(id2)
    @equivalent_abilities[id2] ||= []
    @equivalent_abilities[id2] << id1 unless @equivalent_abilities[id2].include?(id1)
  end

  # Checks if two abilities have the exact same effects
  def self.same_effects?(head_id, body_id)
    return true if head_id == body_id
    return true if @equivalent_abilities[head_id]&.include?(body_id)
    return false
  end

  # Checks if an ability is blacklisted for fusion
  def self.blacklisted_single?(ability_id)
    @blacklisted_singles.include?(ability_id)
  end

  # Checks if a specific pair of abilities is blacklisted for fusion
  def self.blacklisted_pair?(head_id, body_id)
    @blacklisted_pairs.any? { |pair| pair.include?(head_id) && pair.include?(body_id) }
  end

  def self.register_combo(head_id, body_id)
    combo_id = :"ASONE_#{head_id}_#{body_id}"
    return combo_id if @combo_registry.key?(combo_id)

    @combo_registry[combo_id] = [head_id, body_id]

    # Register visual ability for the UI if it hasn't been created yet
    unless GameData::Ability.exists?(combo_id)
      head_name = GameData::Ability.try_get(head_id)&.name || "Unknown"
      body_name = GameData::Ability.try_get(body_id)&.name || "Unknown"

      GameData::Ability.register({
        :id => combo_id,
        :name => "As One",
        :description => "Combines the effects of #{head_name} and #{body_name}."
      })
    end

    self.bind_combo_to_effects(combo_id, head_id, body_id)

    return combo_id
  end

  def self.get_components(combo_id)
    return @combo_registry[combo_id]
  end

  # Automatically register the fusion combo 
  def self.bind_combo_to_effects(combo_id, head_id, body_id)
    return if !defined?(Battle::AbilityEffects)

    Battle::AbilityEffects.constants.each do |const_name|
      handler_hash = Battle::AbilityEffects.const_get(const_name)
      next unless handler_hash.respond_to?(:add) && handler_hash.respond_to?(:[])

      has_head = handler_hash[head_id]
      has_body = handler_hash[body_id]

      if has_head || has_body
        handler_hash.add(combo_id, proc { |*args|
          res1 = has_head ? has_head.call(*args) : nil
          res2 = has_body ? has_body.call(*args) : nil

          next nil if res1.nil? && res2.nil?

          # Numeric / Math Hooks
          if res1.is_a?(Numeric) || res2.is_a?(Numeric)
            base_val = args.find { |arg| arg.is_a?(Numeric) } || 0.0
            val1 = res1.is_a?(Numeric) ? res1 : base_val
            val2 = res2.is_a?(Numeric) ? res2 : base_val

            if base_val == 0.0
              result = base_val + (val1 - base_val) + (val2 - base_val)
            else
              mod1 = val1.to_f / base_val
              mod2 = val2.to_f / base_val

              # If both components try to boost damage, scale down the secondary boost slightly
              mod2 = 1.0 + ((mod2 - 1.0) * 0.5) if mod2 > 1.0 && mod1 > 1.0

              result = base_val * mod1 * mod2
            end
            
            next (base_val.is_a?(Integer) && res1.is_a?(Integer)) ? result.round : result

          # Boolean & Object Hooks
          else
            next true if res1 == true || res2 == true
            next false if res1 == false && res2 == false
            next res1 if !res1.nil?
            next res2 if !res2.nil?
            next nil
          end
        })
      end
    end
  end
end

# Bind all registered combos once scripts are fully loaded
if defined?(Battle::AbilityEffects)
  FusedAbilities.instance_variable_get(:@combo_registry)&.each do |combo_id, comps|
    FusedAbilities.bind_combo_to_effects(combo_id, comps[0], comps[1])
  end
end

#==================================================================
# class FusedPokemon
#==================================================================
class FusedPokemon
  # Override ability getter
  def ability
    return super unless fused?
    return super if !@original_head_data || !@original_body_data
    
    head_abil = @original_head_data.ability
    body_abil = @original_body_data.ability
    
    # Fallback if a component lacks an ability
    return super if !head_abil || !body_abil

    # Duplicate Clause
    return head_abil if FusedAbilities.same_effects?(head_abil.id, body_abil.id)

    # Blacklist Clause
    if FusedAbilities.blacklisted_single?(head_abil.id) || 
      FusedAbilities.blacklisted_single?(body_abil.id) || 
      FusedAbilities.blacklisted_pair?(head_abil.id, body_abil.id)
      return head_abil
    end
    
    # Register and return the combined ability proxy
    combo_id = FusedAbilities.register_combo(head_abil.id, body_abil.id)
    return GameData::Ability.get(combo_id)
  end

  def ability_id
    return ability.id if fused?
    return super
  end
end

#==================================================================
# class Battle::Battler
#==================================================================
class Battle::Battler
  alias vanilla_hasActiveAbility? hasActiveAbility? unless method_defined?(:vanilla_hasActiveAbility?)

  def hasActiveAbility?(check_ability = nil, ignore_fainted = false)
    return false if fainted? && !ignore_fainted
    return false if @effects[PBEffects::GastroAcid]
    
    # Neutralizing Gas Infinite Loop Protection
    if check_ability != :NEUTRALIZINGGAS
      @is_checking_ng = true unless defined?(@is_checking_ng)
      if !@is_checking_ng
        @is_checking_ng = true
        has_ng = @battle.pbCheckGlobalAbility(:NEUTRALIZINGGAS)
        @is_checking_ng = false
        return false if has_ng
      end
    end

    current_ability = self.ability_id
    return false if current_ability.nil?

    # Check Fused Components
    combo = FusedAbilities.get_components(current_ability)
    if combo
      if check_ability.is_a?(Array)
        return true if check_ability.any? { |ab| combo.include?(ab) }
      elsif check_ability
        return true if combo.include?(check_ability)
      else
        return true # General check: "Does this battler have any active ability?"
      end
    end

    # Standard non-fused fallback check
    if check_ability.is_a?(Array)
      return check_ability.include?(current_ability)
    elsif check_ability
      return current_ability == check_ability
    end

    return true
  end
end


#==================================================================
# module Battle::AbilityEffects
#==================================================================
module Battle::AbilityEffects
  class << self
    alias vanilla_trigger trigger unless method_defined?(:vanilla_trigger)

    def trigger(hash, *args, ret: false)
      ability = args[0]
      components = FusedAbilities.get_components(ability)
      
      # If this is not a fused ability, proceed with the normal engine logic
      return vanilla_trigger(hash, *args, ret: ret) if components.nil?

      # Create argument copies for both the Head and Body components
      args1 = args.dup
      args1[0] = components[0]
      
      args2 = args.dup
      args2[0] = components[1]

      # Trigger both component abilities independently
      res1 = vanilla_trigger(hash, *args1, ret: ret)
      res2 = vanilla_trigger(hash, *args2, ret: ret)

      # Duck Typing Math Hooks
      if ret.is_a?(Numeric)
        res1 = ret if res1.is_a?(TrueClass) || res1.is_a?(FalseClass)
        res2 = ret if res2.is_a?(TrueClass) || res2.is_a?(FalseClass)

        base_val = ret.to_f
        
        if base_val == 0.0
          # Additive Math (e.g., Priority Bracket adjustments usually return 0)
          result = ret + (res1 - ret) + (res2 - ret)
        else
          # Multiplicative Math (e.g., SpeedCalc, Damage Multipliers)
          mod1 = res1.to_f / base_val
          mod2 = res2.to_f / base_val
          result = base_val * mod1 * mod2
        end
        
        # Preserve native Integer or Float data types for the engine
        return ret.is_a?(Integer) ? result.round : result

      # Boolean & Object Hooks
      else
        # If either component successfully triggered (returned true), the whole ability triggers
        return true if res1 == true || res2 == true
        
        # If both explicitly failed or didn't trigger, safely return false
        return false if res1 == false && res2 == false
        
        # For object-returning hooks (like ModifyMoveBaseType returning a :TYPE symbol)
        return res1 if res1 != ret
        return res2 if res2 != ret
        
        # Fallback to the default return
        return ret
      end
    end
  end
end