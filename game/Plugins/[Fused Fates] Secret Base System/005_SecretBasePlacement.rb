#================================================================================================
# Pokémon Fused Fates Secret Base System - 005_SecretBasePlacement.rb
#================================================================================================

#==================================================================
# module SecretBasePlacer
#==================================================================
module SecretBasePlacer
  # Calculates the X and Y coordinates of the tile directly in front of the player
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

  # Validates if a decoration can be placed at the target coordinates
  def self.valid_target_tile?(x, y)
    # Check if the tile is out of map boundaries
    return false if x < 0 || y < 0 || x >= $game_map.width || y >= $game_map.height
    
    # Check if an event already exists on this specific tile
    $game_map.events.values.each do |event|
      return false if event.x == x && event.y == y
    end
    
    # Check passability
    return false unless $game_map.passable?(x, y, 0)
    
    return true
  end

  # Handles the logic for placing a new decoration
  def self.place_decoration(id)
    x, y = get_facing_coords

    unless valid_target_tile?(x, y)
      pbPlayBuzzerSE
      return false
    end

    # Generate a unique instance ID using the current time and a random number
    instance_id = "#{Time.now.to_i}_#{rand(1000)}"
    data = { id: id, x: x, y: y}

    # Initialize the hash for this map
    $PokemonGlobal.placed_decorations[$game_map.map_id] ||= {}

    # Save the data so it loads on map re-entry
    $PokemonGlobal.placed_decorations[$game_map.map_id][instance_id] = data

    # Physically spawn the event into the map
    spawn_event(instance_id, data)

    pbPlayDecisionSE
    return true
  end

  # Physically spawns the event and links a graphic sprite to it
  def self.spawn_event(instance_id, data)
    dec_id = data[:id]
    x = data[:x]
    y = data[:y]

    # Generate the Game_Event
    event = Game_Event.create_decoration_event($game_map, dec_id, x, y, instance_id)

    # Add the newly created event to the map's active event list
    $game_map.events[event.id] = event

    # Force the sprite to draw immediately
    if $scene.is_a?(Scene_Map)
      spriteset = nil

      if $scene.spriteset
        spriteset = $scene.spriteset($game_map.map_id)
      end

      if spriteset
        viewport = spriteset.instance_variable_get(:@viewport1)
        char_sprites = spriteset.instance_variable_get(:@character_sprites)

        if viewport && char_sprites
          char_sprites.push(Sprite_Character.new(viewport, event))
        end
      end
    end

    return event
  end

  # Removes a decoration from the map and the save data
  def self.pickup_decoration(instance_id)
    # Locate the event on the map matching the provided instance_id
    target_event = $game_map.events.values.find { |e| e.is_decoration && e.instance_id == instance_id }

    if target_event
      dec_id = target_event.decoration_id

      # Remove from the global save data
      if $PokemonGlobal.placed_decorations[$game_map.map_id]
        $PokemonGlobal.placed_decorations[$game_map.map_id].delete(instance_id)
      end

      # Remove the event from the map's logic array
      $game_map.events.delete(target_event.id)

      # Locate the visual sprite and permanently dispose of it
      if $scene.is_a?(Scene_Map)
        spriteset = nil

        if $scene.spriteset
          spriteset = $scene.spriteset($game_map.map_id)
        end

        if spriteset
          char_sprites = spriteset.instance_variable_get(:@character_sprites)
          if char_sprites
            sprite = char_sprites.find { |s| s.character == target_event }
            if sprite
              sprite.dispose
              char_sprites.delete(sprite)
            end
          end
        end
      end

      # Clear the event's internal data to prevent memory leaks
      target_event.erase

      pbPlayDecisionSE

      # Return the decoration ID so the calling script can give the item back to the player
      return dec_id
    end

    return nil
  end
end

#==================================================================
# class Game_Event < Game_Character
#==================================================================
class Game_Event < Game_Character
  attr_accessor :is_decoration
  attr_accessor :decoration_id
  attr_accessor :instance_id

  # Transforms a standard event into a function decoration
  def setup_as_decoration(dec_id, instance_id)
    @is_decoration = true
    @decoration_id = dec_id
    @instance_id = instance_id

    # Dynamic Graphic Assignment
    data = Decoration.get(dec_id)
    if data && data[:graphic]
      graphic_name = data[:graphic].gsub(/\.png$/i, '')

      @character_name = "Decorations/#{graphic_name}"
    end

    @always_on_top = false
    is_passable = Decoration.passable?(dec_id)
    @through = is_passable

    # Stop decorations from animating like walking NPCs
    @step_anime = false
    @direction_fix = true

    if @page
      @page.graphic.character_name = @character_name
      @page.always_on_top = false
      @page.through = is_passable
      @page.graphic.direction = 2
    end
  end

  # Dynamically spawn a new event into the map
  def self.create_decoration_event(map, dec_id, x, y, instance_id)
    # Generate a dummy event in memory
    rpg_event = RPG::Event.new(x, y)

    # Assign a unique Event ID higher than the existing event IDs
    existing_keys = map.events.keys
    rpg_event.id = existing_keys.empty? ? 1 : existing_keys.max + 1
    rpg_event.name = "Decoration_#{instance_id}"

    # Create a blank event page
    page = RPG::Event::Page.new
    page.trigger = 0 # Action Button trigger

    # Assign the page to the event
    rpg_event.pages = [page]

    # Initialize the actual Game_Event object
    event = Game_Event.new(map.map_id, rpg_event, map)

    # Configure the custom decoration parameters
    event.setup_as_decoration(dec_id, instance_id)

    # Physically move the event to the target coordinates
    event.moveto(x, y)

    return event
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