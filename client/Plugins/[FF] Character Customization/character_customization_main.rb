#================================================================================================
# Pokémon Fused Fates - Character Customization System Main
#================================================================================================

class Player
  attr_accessor :hair_color
  attr_accessor :eye_color
  attr_accessor :skin_color
  attr_accessor :outfit_color, :current_outfit
  attr_accessor :wardrobe

  # Initialize the new data when the player object is created
  alias_method :character_customization_initialize, :initialize
  def initialize(*args)
    @hair_color       = 0,
    @eye_color        = 0,
    @skin_color       = 0,
    @outfit_color     = 0,
    @current_outfit   = 0,
    @wardrobe         = nil
    character_customization_initialize(*args)
  end
end