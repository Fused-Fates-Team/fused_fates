#================================================================================================
# Pokémon Fused Fates Fusion System - 001_FusedPokemon.rb
# ===============================================================================================

#==================================================================
# class FusedPokemon < Pokemon
#==================================================================
class FusedPokemon < Pokemon
  attr_accessor :fusion_head, :fusion_body
  attr_accessor :original_head_data, :original_body_data

  # Alias Initialization to include fusion tracking
  def initialize(species, level, head = nil, body = nil)
    @fusion_head = head
    @fusion_body = body
    
    # If it's a fusion, initialize the base Pokemon object using the head species
    super(head || species, level)
  end

  # Delegate core attributes to the primary Pokémon
  def species=(species_id)
    return super(species_id) unless fused?
    
    new_species_data = GameData::Species.get(species_id)
    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)

    if head_data && head_data.respond_to?(:evolutions) && head_data.evolutions.any? { |evo| evo[0] == new_species_data.species }
      @fusion_head = new_species_data.species
    elsif body_data && body_data.respond_to?(:evolutions) && body_data.evolutions.any? { |evo| evo[0] == new_species_data.species }
      @fusion_body = new_species_data.species
    end

    super(species_id)
  end

  def name
    return super unless respond_to?(:fused?) && fused?
    return generate_fusion_name
  end

  def speciesName
    return super unless respond_to?(:fused?) && fused?
    return generate_fusion_name
  end

  # Override species_name method
  def species_name
    return speciesName
  end

  # Generate a mashup name
  def generate_fusion_name
    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)
    
    head_name = head_data ? head_data.name : "Unknown"
    body_name = body_data ? body_data.name : "Unknown"
    
    # Combination name logic (first half of head + last half of body)
    return "#{head_name[0..(head_name.length / 2)]}#{body_name[(body_name.length / 2)..-1]}"
  end

  # Procedural Type System (Head gives Primary type, Body gives Secondary type)
  def types
    return super unless respond_to?(:fused?) && fused?

    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)
    return super unless head_data && body_data

    type1 = head_data.types[0]
    type2 = body_data.types[1] || body_data.types[0]
    
    return type1 == type2 ? [type1] : [type1, type2]
  end

  # Ensure type checking methods can read the custom array
  def has_type?(type)
    return types.include?(type)
  end

  # Procedural stat calculation
  def baseStats
    return super unless respond_to?(:fused?) && fused?

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

  # Override base_stats method
  def base_stats
    return baseStats
  end

  def compatible_with_move?(move_id)
    return super(move_id) unless respond_to?(:fused?) && fused?
    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)

    head_compat = head_data.respond_to?(:compatible_with_move?) ? head_data.compatible_with_move?(move_id) : false
    body_compat = body_data.respond_to?(:compatible_with_move?) ? body_data.compatible_with_move?(move_id) : false

    return head_compat || body_compat || super(move_id)
  end

  def getMoveList
    return super unless respond_to?(:fused?) && fused?
    return fusion_level_up_moves
  end

  # Returns a combined, unique array of all level-up move IDs from both Components
  def fusion_level_up_moves
    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)

    moves_list = []

    extract_moves = lambda do |species_data|
      return unless species_data && species_data.respond_to?(:moves) && species_data.moves
      species_data.moves.each do |move_data|
        if move_data.is_a?(Array) && move_data.length >= 2
          moves_list.push([move_data[0], move_data[1]])
        end
      end
    end

    extract_moves.call(head_data)
    extract_moves.call(body_data)
    moves_list.sort_by! { |move| move[0] }
    
    return moves_list
  end

  # When a fusion gains exp, both parts will also gain exp
  def exp=(value)
    return super(value) unless respond_to?(:fused?) && fused?

    v = @exp*1
    super(value)
    v = value - v

    @original_head_data.exp += v if @original_head_data
    @original_body_data.exp += v if @original_body_data
  end

  def base_exp
    return super unless respond_to?(:fused?) && fused?
    
    head_data = GameData::Species.get(@fusion_head)
    body_data = GameData::Species.get(@fusion_body)
    
    h = (head_data.base_exp * 20.0) / head_data.base_stats.values.sum
    b = (body_data.base_exp * 20.0) / body_data.base_stats.values.sum
    
    return ((self.baseStats.values.sum * (h+b))/40.0).round.to_i
  end

  # Check if the Pokémon is fused
  def fused?
    return !@fusion_head.nil? && !@fusion_body.nil?
  end

  def play_cry(volume = 90, pitch = nil)
    return super(volume, pitch) unless respond_to?(:fused?) && fused?
    GameData::Species.play_cry_from_pokemon(@original_head_data, volume*2/3, pitch) if @original_head_data
    GameData::Species.play_cry_from_pokemon(@original_body_data, volume/3, pitch) if @original_body_data
  end
end