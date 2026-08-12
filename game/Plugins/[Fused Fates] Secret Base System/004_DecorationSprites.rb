#================================================================================================
# Pokémon Fused Fates Secret Base System - 004_DecorationSprites.rb
#================================================================================================

#==================================================================
# class DecorationSprite
#==================================================================
class DecorationSprite < Sprite
  attr_accessor :decoration_id
  attr_accessor :character # The Game_Event on the map

  def initialize(viewport = nil, id = nil, character = nil)
    super(viewport)
    @decoration_id = id
    @character = character

    refresh
    update
  end

  # Setter for decoration_id that automatically refreshes the sprite
  def decoration_id=(value)
    return if @decoration_id == value
    @decoration_id = value
    refresh
  end

  # Loads the bitmap and sets the sprite's origin point
  def refresh
    # Clear the bitmap if the ID is invalid or missing
    if @decoration_id.nil? || !Decoration.exists?(@decoration_id)
      self.bitmap = nil
      return
    end

    # Fetch the graphic from the registry
    self.bitmap = Decoration.load_bitmap(@decoration_id)

    # Center horizontally, align bottom vertically
    if self.bitmap && !self.bitmap.disposed?
      self.ox = self.bitmap.width / 2
      self.oy = self.bitmap.height
    end
  end

  # Syncs the sprite's position with the underlying Game_Event
  def update
    super
    if @character
      self.x = @character.screen_x
      self.y = @character.screen_y
      self.z = @character.screen_z

      # Hide the sprite if the event itself is transparent/erased
      self.visible = !@character.transparent
    end
  end

  # Cleans up the sprite when it's no longer needed
  def dispose
  end
end

#==================================================================
# class Spriteset_Map 
#==================================================================
class Spriteset_Map
  alias_method :secret_base_spriteset_init, :initialize
  
  def initialize(map = nil)
    if map.nil?
      secret_base_spriteset_init
    else
      secret_base_spriteset_init(map)
    end
    
    # Modify the sprite array in-place
    if @character_sprites
      @character_sprites.map! do |sprite|
        # Check if the sprite belongs to a map event
        if sprite.respond_to?(:character) && sprite.character.is_a?(Game_Event)
          event = sprite.character
          
          # Check if this specific event is flagged as a decoration
          if event.respond_to?(:is_decoration) && event.is_decoration
            # Dispose of the default empty RMXP sprite to prevent memory leaks
            sprite.dispose 
            
            # Replace it in the array with our custom DecorationSprite
            DecorationSprite.new(@viewport1, event.decoration_id, event)
          else
            sprite # Return standard events untouched
          end
        else
          sprite # Return the player and dependent events untouched
        end
      end
    end
    
    # Dynamically adds a DecorationSprite for events spawned after map initialization
    def add_decoration_sprite(event)
      return unless event.respond_to?(:is_decoration) && event.is_decoration
      @character_sprites ||= []
      dec_sprite = DecorationSprite.new(@viewport1, event.decoration_id, event)
      @character_sprites.push(dec_sprite)
    end
  end
end