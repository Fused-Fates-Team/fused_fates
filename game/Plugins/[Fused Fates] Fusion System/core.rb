#================================================================================================
# Pokémon Fused Fates Fusion System - core
#================================================================================================

#================================================================
# class FusedPokemon < Pokemon
#================================================================
class FusedPokemon < Pokemon
  attr_accessor :fusion_head
  attr_accessor :fusion_body
  attr_accessor :original_head_data
  attr_accessor :original_body_data

  # Initialization to include fusion tracking
  def initialize(species, level, fix_gender = true, infer_shiny = true, head = nil, body = nil, og_head = nil, og_body = nil)
    super(species, level, fix_gender, infer_shiny)
    @fusion_head = head
    @fusion_body = body
    @original_head_data = og_head
    @original_body_data = og_body
  end

  # Check if the Pokémon is currently fused
  def fused?
    return !@fusion_head.nil? && !@fusion_body.nil?
  end

  # Procedural Stat Calculation (Blends Head and Body stats)
  def base_stats
    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)

    ret = {}
    [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
      # Example formula: 2/3 Body stats + 1/3 Head stats
      ret[stat] = ((body_data.baseStats[stat] * 2) + (head_data.baseStats[stat])) / 3
    end
    return ret
  end

  # Procedural Type System (Head gives Primary type, Body gives Secondary type)
  def types
    return super unless fused?

    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)
    return super unless head_data && body_data

    type1 = head_data.types[0]
    type2 = body_data.types[1] || body_data.types[0]
    
    # If both types end up identical, return just one type, otherwise return both
    if type1 == type2
      return [type1]
    else
      return [type1, type2]
    end
  end

  # Ensure type checking methods can read the custom array
  def has_type?(type)
    return types.include?(type)
  end
end