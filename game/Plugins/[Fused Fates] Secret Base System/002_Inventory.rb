#================================================================================================
# Pokémon Fused Fates Secret Base System - 002_Inventory.rb
#================================================================================================

#==================================================================
# module SecretBaseInventory
#==================================================================
module SecretBaseInventory
  # Retrieves all active pockets available in the decoration database
  def self.pockets
    return Decoration.categories
  end

  # Provides clean, display-friendly names for each pocket category
  def self.pocket_name(category)
    case category.to_sym
    when :desk
      return _INTL("Desk")
    when :chair
      return _INTL("Chair")
    when :plant
      return _INTL("Plant")
    when :ornament
      return _INTL("Ornament")
    when :mat
      return _INTL("Mat")
    when :poster
      return _INTL("Poster")
    when :doll
      return _INTL("Doll")
    when :cushion
      return _INTL("Cushion")
    end
  end

  # Returns total unique types or total item count inside a specific pocket
  def self.pocket_count(player, category)
    return 0 unless player.is_a?(Player)
    items = player.decorations_in_pocket(category)
    return items.sum { |id| player.secret_base_decorations[id] }
  end
end