#================================================================================================
# Pokémon Fused Fates Secret Base System - 006_SecretBasePlacement.rb
#================================================================================================

#==================================================================
# module SecretBasePlacer
#==================================================================
module SecretBasePlacer
  def self.get_facing_coords
    x = $game_player.x
    y = $game_player.y
    case $game_player.direction
    when 2 then y += 1 # Down
    when 4 then x -= 1 # Left
    when 6 then x += 1 # Right
    when 8 then y -= 1 # Up
    end
    return x, y
  end

  def self.valid_target_tile?
    x, y = get_facing_coords
    return false unless $game_map.valid?(x, y)
    return false unless $game_map.passable?(x, y, 0, $game_player)
    
    $game_map.events.values.each do |event|
      return false if event.x == x && event.y == y
    end
    return false if $game_player.x == x && $game_player.y == y
    return true
  end

  def self.place_decoration(id)
    return false unless Decoration.exists?(id)
    unless valid_target_tile?
      pbMessage(_INTL("You can't place a decoration there!"))
      return false
    end

    if $Player.respond_to?(:has_decoration?) && !$Player.has_decoration?(id, 1)
      pbMessage(_INTL("You don't own this decoration!"))
      return false
    end

    x, y = get_facing_coords
    map_id = $game_map.map_id

    $PokemonGlobal.placed_decorations ||= {}
    $PokemonGlobal.placed_decorations[map_id] ||= {}

    # Find next available instance ID
    instance_id = 1
    while $PokemonGlobal.placed_decorations[map_id][instance_id] || $game_map.events[instance_id]
      instance_id += 1
    end

    # Save data
    $PokemonGlobal.placed_decorations[map_id][instance_id] = {
      id: id,
      x: x,
      y: y
    }

    if $Player.respond_to?(:remove_decoration)
      $Player.remove_decoration(id, 1)
    end

    spawn_event(instance_id, { id: id, x: x, y: y })
    pbMessage(_INTL("Placed decoration successfully!"))
    $game_map.need_refresh = true
    return true
  end

  def self.spawn_event(instance_id, data)
    return if $game_map.events[instance_id]

    map_id = $game_map.map_id

    # Create a valid RPG::Event object so Game_Event.new receives an object with an ID and name
    rpg_event = RPG::Event.new(data[:x], data[:y])
    rpg_event.id = instance_id
    rpg_event.name = "Decoration_#{instance_id}"

    new_game_event = Game_Event.new(map_id, rpg_event)
    new_game_event.moveto(data[:x], data[:y])
    
    # CRITICAL: Force transparent to false so the sprite renders immediately
    new_game_event.transparent = false

    $game_map.events[instance_id] = new_game_event

    # Live injection utilizing v21.1's .spriteset property accessor or @spriteset
    spriteset = $scene.respond_to?(:spriteset) ? $scene.spriteset : $scene.instance_variable_get(:@spriteset)
    if spriteset
      viewport = spriteset.instance_variable_get(:@viewport1)
      char_sprites = spriteset.instance_variable_get(:@character_sprites)
      
      if viewport && char_sprites
        exists = char_sprites.any? { |s| s.is_a?(DecorationSprite) && s.character == new_game_event }
        unless exists
          new_sprite = DecorationSprite.new(viewport, data[:id], new_game_event)
          char_sprites.push(new_sprite)
        end
      end
    end
  end

  def self.pickup_decoration(instance_id)
    map_id = $game_map.map_id
    return false unless $PokemonGlobal.placed_decorations && $PokemonGlobal.placed_decorations[map_id]
    
    data = $PokemonGlobal.placed_decorations[map_id][instance_id]
    return false unless data

    decoration_id = data[:id]
    
    # Remove saved data
    $PokemonGlobal.placed_decorations[map_id].delete(instance_id)
    
    # Remove logical event from map
    if $game_map.events[instance_id]
      $game_map.events.delete(instance_id)
    end

    # Clean up associated sprites from viewport character sprites array
    if $scene.is_a?(Scene_Map)
      spriteset = $scene.respond_to?(:spriteset) ? $scene.spriteset : $scene.instance_variable_get(:@spriteset)
      if spriteset
        char_sprites = spriteset.instance_variable_get(:@character_sprites)
        if char_sprites
          char_sprites.delete_if do |s|
            if s.is_a?(DecorationSprite) && (s.character == nil || !$game_map.events.values.include?(s.character))
              s.dispose
              true
            else
              false
            end
          end
        end
      end
    end

    if $Player.respond_to?(:add_decoration)
      $Player.add_decoration(decoration_id, 1)
    end
    pbMessage(_INTL("Picked up placed decoration."))
    $game_map.need_refresh = true
    return true
  end
end

#==================================================================
# class Game_Map
#==================================================================
class Game_Map
  alias_method :secret_base_setup, :setup
  def setup(map_id)
    secret_base_setup(map_id)
    
    if $PokemonGlobal && $PokemonGlobal.placed_decorations && $PokemonGlobal.placed_decorations[map_id]
      $PokemonGlobal.placed_decorations[map_id].each do |instance_id, data|
        next unless Decoration.exists?(data[:id])
        SecretBasePlacer.spawn_event(instance_id, data)
      end
    end
  end
end

#==================================================================
# class PokemonGlobalMetadata
#==================================================================
class PokemonGlobalMetadata
  attr_accessor :placed_decorations
  
  def placed_decorations
    @placed_decorations ||= {}
    return @placed_decorations
  end
end