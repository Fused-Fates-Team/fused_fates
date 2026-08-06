#================================================================================================
# Pokémon Fused Fates Fusion System - 001_FusedPokemon.rb
#================================================================================================

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

  # Check if the Pokémon is fused
  def fused?
    return !@fusion_head.nil? && !@fusion_body.nil?
  end

  # Delegate core attributes to the primary Pokémon
  def species=(species_id)
    return super(species_id) unless fused?
    
    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)

    head_evolved = (head_data && head_data.evolutions.any? { |evo| evo[0] == species_id })
    body_evolved = (body_data && body_data.evolutions.any? { |evo| evo[0] == species_id })

    if head_evolved
      @fusion_head = species_id
      @_virtual_species_data = nil # Clear cached proxy
    elsif body_evolved
      @fusion_body = species_id
      @_virtual_species_data = nil # Clear cached proxy
    end

    super(species_id)
  end

  # Dynamic species data proxy
  def species_data
    return super unless respond_to?(:fused?) && fused?
    @_virtual_species_data ||= create_virtual_species_data
    return @_virtual_species_data
  end

  def create_virtual_species_data
    head_data = GameData::Species.try_get(@fusion_head)
    body_data = GameData::Species.try_get(@fusion_body)
    return super unless head_data && body_data

    proxy = Object.new
    proxy.instance_variable_set(:@head, head_data)
    proxy.instance_variable_set(:@body, body_data)

    def proxy.id; :VIRTUAL_FUSION; end
    def proxy.name
      head_name = @head ? @head.name : "Unknown"
      body_name = @body ? @body.name : "Unknown"
    
      # Combination name logic (first half of head + last half of body)
      return "#{head_name[0..(head_name.length / 2)]}#{body_name[(body_name.length / 2)..-1]}"
    end

    def play_cry(volume = 90, pitch = nil)
      GameData::Species.play_cry_from_pokemon(@original_head_data, volume*2/3, pitch) if @original_head_data
      GameData::Species.play_cry_from_pokemon(@original_body_data, volume/3, pitch) if @original_body_data
    end

    # Type blending: Head gives type 1, Body gives type 2 (fallback to head type 1 if single)
    def proxy.types
      t1 = @head.types[0]
      t2 = @body.types[1] || @body.types[0]
      t1 == t2 ? [t1] : [t1, t2]
    end

    def proxy.has_type?(type)
      types.include(type)
    end

    # Stat blending (even average)
    def proxy.baseStats  
      ret = {}
      [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        head_stat = (@head.respond_to?(:base_stats) && @head.base_stats[stat]) || 
                    (@head.respond_to?(:baseStats) && @head.baseStats[stat]) || 0
        body_stat = (@body.respond_to?(:base_stats) && @body.base_stats[stat]) || 
                    (@body.respond_to?(:baseStats) && @body.baseStats[stat]) || 0
        ret[stat] = ((head_stat + body_stat) / 2).round
      end
      return ret
    end

    def proxy.base_exp
      h = (@head.base_exp * 20) / @head.base_stats.values.sum
      b = (@body.base_exp * 20) / @body.base_stats.values.sum
      return ((self.baseStats.values.sum * (h+b))/40).round.to_i
    end

    def proxy.exp=(value)
      v = @exp*1

      @original_head_data.exp += v if @original_head_data
      @original_body_data.exp += v if @original_body_data
    end

    def proxy.height
      (@head.height + @body.height) / 2
    end

    def proxy.weight
      (@head.weight + @body.weight) / 2
    end

    def proxy.egg_groups
      
    end

    def proxy.gender
      @body.gender
    end

    def proxy.category
      "#{@head.category} / #{@body.category}"
    end

    def proxy.pokedex_entry
      "A fused Pokémon combining the traits of #{@head.name} and #{@body.name}."
    end

    def proxy.evolutions
      @head.evolutions && @body.evolutions
    end

    def proxy.method_missing(method, *args, &block)
      if @head.respond_to?(method)
        @head.send(method, *args, &block)
      else
        super
      end
    end

    def proxy.respond_to_missing?(method, include_private = false)
      @head.respond_to?(method, include_private) || super
    end

    return proxy
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
end