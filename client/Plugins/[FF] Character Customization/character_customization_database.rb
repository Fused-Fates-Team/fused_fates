#================================================================================================
# Pokémon Fused Fates - Character Customization System Database
#================================================================================================

module CharacterCustomization
  # Database of available options
  character_customization_database = {
    :HAIR_COLOR => {
      :id => "HAIR_COLOR",
      :names => ["Blonde", "Red", "Brown", "Black"],
      :colors => [""]
    },
    :EYE_COLOR => {
      :id => "EYE_COLOR",
      :names => ["Blue", "Gray", "Green", "Brown",
                 "Amber", "Hazel"],
      :colors => [""]
    },
    :SKIN_COLOR => {
      :id => "SKIN_COLOR",
      :names => ["A", "B", "C", "D",
                 "E", "F"],
      :colors => [""]
    },
    :OUTFIT => {
      :id => "OUTFIT",
      :names => ["Pajamas", "Athletic", "Fancy", "Punk",
                 "Retro"],
      :colors => [""]
    }
  }

  # Apply tone filter to sprite
  def self.apply_tone(sprite, color)
  end

  # Apply sprite to player base
  def self.apply_sprite(sprite)
  end
end