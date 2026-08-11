#================================================================================================
# Pokémon Fused Fates Secret Base System - 004_DecorationSprites.rb
#================================================================================================

#==================================================================
# class DecorationSprite < Sprite
#==================================================================
class DecorationSprite < Sprite
  attr_accessor :decoration_id
  attr_accessor :character # The logical Game_Event on the map

  def initialize(viewport = nil, id = nil, character = nil)
    super(viewport)
    @decoration_id = id
    @character = character
    refresh
  end

  def decoration_id=(value)
    return if @decoration_id == value
    @decoration_id = value
    refresh
  end

  def refresh
    if self.bitmap && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    
    if @decoration_id && Decoration.exists?(@decoration_id)
      self.bitmap = Decoration.load_bitmap(@decoration_id)
      
      if self.bitmap
        self.ox = self.bitmap.width / 2
        self.oy = self.bitmap.height
      end
    else
      self.bitmap = nil
    end
  end

  def update
    super
    if @character
      # Prevent ghosting if the logical event was picked up/removed
      if @character.is_a?(Game_Event) && $game_map.events[@character.id] != @character
        self.visible = false
        return
      end

      self.x = @character.screen_x
      self.y = @character.screen_y
      self.z = @character.screen_z
      self.opacity = @character.opacity
      self.visible = @character.respond_to?(:transparent) ? !@character.transparent : true
    end
  end

  def dispose
    if self.bitmap && !self.bitmap.disposed?
      self.bitmap.dispose
    end
    super
  end
end

#==================================================================
# class Spriteset_Map
#==================================================================
class Spriteset_Map
  alias_method :secret_base_initialize, :initialize
  
  def initialize(*args)
    secret_base_initialize(*args)
    
    # Automatically bind decoration sprites when loading map in v21.1
    if $game_map && $PokemonGlobal && $PokemonGlobal.placed_decorations
      map_id = $game_map.map_id
      if $PokemonGlobal.placed_decorations[map_id] && @character_sprites && @viewport1
        $PokemonGlobal.placed_decorations[map_id].each do |instance_id, data|
          event = $game_map.events[instance_id]
          if event
            existing = @character_sprites.find { |s| s.is_a?(DecorationSprite) && s.character == event }
            unless existing
              new_sprite = DecorationSprite.new(@viewport1, data[:id], event)
              @character_sprites.push(new_sprite)
            end
          end
        end
      end
    end
  end
end