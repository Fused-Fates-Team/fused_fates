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

    @name = generate_fusion_name if fused?
  end

  # Check if the Pokémon is currently fused
  def fused?
    return !@fusion_head.nil? && !@fusion_body.nil?
  end

  # Generate a mashup name
  def generate_fusion_name
    # Fallback to base species name if not fused yet during early super initialization
    return super.respond_to?(:species_name) ? super.species_name : GameData::Species.get(@species).name unless fused?

    head_name = GameData::Species.get(@fusion_head).name
    body_name = GameData::Species.get(@fusion_body).name

    # Split names roughly in half
    head_cut = [1, (head_name.length / 2.0).ceil].max
    body_cut = [0, (body_name.length / 2.0).floor].max

    mashup = head_name[0, head_cut] + body_name[body_cut..-1]
    return mashup.strip
  end

  # Override name method to ensure it always returns the mashup if requested
  def name
    return @name || generate_fusion_name
  end

  # Override species_name
  def species_name
    return generate_fusion_name if fused?
    return super
  end

  # Override speciesName
  def speciesName
    return generate_fusion_name if fused?
    return super
  end

  # Procedural Stat Calculation (Blends Head and Body stats)
  def base_stats
    unless fused?
      species_data = GameData::Species.get(@species)
      return species_data.base_stats if species_data.respond_to?(:base_stats) && species_data.base_stats
      return species_data.baseStats if species_data.respond_to?(:baseStats) && species_data.baseStats
      return {}
    end

    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)
    return {} unless head_data && body_data

    ret = {}
    [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
      head_stat = (head_data.respond_to?(:base_stats) && head_data.base_stats[stat]) || 
                  (head_data.respond_to?(:baseStats) && head_data.baseStats[stat]) || 0
      body_stat = (body_data.respond_to?(:base_stats) && body_data.base_stats[stat]) || 
                  (body_data.respond_to?(:baseStats) && body_data.baseStats[stat]) || 0
      ret[stat] = ((head_stat + body_stat) / 2.0).round
    end
    return ret
  end

  def baseStats
    return base_stats
  end

  # Procedural Type System (Head gives Primary type, Body gives Secondary type)
  def types
    return super unless fused?

    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)
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