#================================================================================================
# Pokémon Fused Fates - Seasons System Main
#================================================================================================

module Seasons
  # Season types
  SPRING = 0
  SUMMER = 1
  AUTUMN = 2
  WINTER = 3

  # Simple calculation based on month
  def self.current_season
    month = pbGetTimeNow.mon
    return SPRING if [1, 5, 9].include?(month)
    return SUMMER if [2, 6, 10].include?(month)
    return AUTUMN if [3, 7, 11].include?(month)
    return WINTER if [4, 8, 12].include?(month)
  end

  # Master map redirection
  # Example script call: 
  # base_map = 78
  # target = Seasons.get_seasonal_map(base_map)
  # pbTransferPlayer(target, x, y, direction)
  def self.get_seasonal_map(base_map_id)
    # If a map is a "seasonal" map, redirect to specific ID
    # e.g., Map 78 has 4 variants based on season
    seasonal_variants = {
      77 => [1, 2, 3, 4], # Nuvema Town
      78 => [1, 2, 3, 4], # Route 1
      79 => [1, 2, 3, 4], # Accumula Town
      80 => [1, 2, 3, 4], # Route 2
      81 => [1, 2, 3, 4], # Striaton City
      82 => [1, 2, 3, 4], # Dreamyard
      83 => [1, 2, 3, 4], # Route 3
      84 => [1, 2, 3, 4], # Nacrene City
      85 => [1, 2, 3, 4], # Pinwheel Forest
    }

    return seasonal_variants[base_map_id][self.current_season] if seasonal_variants.key?(base_map_id)
    return base_map_id
  end
end

#====================================================================
# Game_Map Extension
#====================================================================

class Game_Map
  alias_method :seasonal_setup, :setup

  def setup(map_id)
    target_id = map_id

    # If a map is a "seasonal" map, redirect to specific ID
    # e.g., Map 78 has 4 variants based on season
    seasonal_variants = {
      77 => [1, 2, 3, 4], # Nuvema Town
      78 => [1, 2, 3, 4], # Route 1
      79 => [1, 2, 3, 4], # Accumula Town
      80 => [1, 2, 3, 4], # Route 2
      81 => [1, 2, 3, 4], # Striaton City
      82 => [1, 2, 3, 4], # Dreamyard
      83 => [1, 2, 3, 4], # Route 3
      84 => [1, 2, 3, 4], # Nacrene City
      85 => [1, 2, 3, 4], # Pinwheel Forest
    }
    
    if seasonal_variants.key?(map_id)
      target_id = seasonal_variants[map_id][Seasons.current_season]
    end

    seasonal_setup(target_id)
  end
end

#====================================================================
# PokemonGlobalMetadata Extension
#====================================================================

class PokemonGlobalMetadata
  attr_accessor :seasonal_event_data

  def seasonal_event_data
    @seasonal_event_data ||= {}
    return @seasonal_event_data
  end
end