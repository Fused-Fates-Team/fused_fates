#================================================================================================
# Pokémon Fused Fates Secret Base System - 001_Player.rb
#================================================================================================

#==================================================================
# class Player
#==================================================================
class Player
  attr_accessor :secret_base_decorations

  alias_method :decoration_init, :initialize
  def initialize(*args)
    decoration_init(*args)
    # Hash mapping decoration IDs to quanitites owned
    @secret_base_decorations = Hash.new(0)
  end

  # Adds a decoration to the player's storage
  def add_decoration(id, qty = 1)
    return false unless Decoration.exists?(id)
    id = id.to_sym
    @secret_base_decorations[id] = [0, @secret_base_decorations[id] + qty].max
    return true
  end

  # Removes a decoration from the player's storage
  def remove_decoration(id, qty = 1)
    return false unless Decoration.exists?(id)
    id = id.to_sym
    return false if @secret_base_decorations[id] < qty
    @secret_base_decorations[id] -= qty
    @secret_base_decorations.delete(id) if @secret_base_decorations[id] <= 0
    return true
  end

  # Verifies if the player currently owns at least the specified quantity
  def has_decoration?(id, qty = 1)
    return false unless Decoration.exists?(id)
    id = id.to_sym
    return @secret_base_decorations[id] >= qty
  end

  # Groups all currently owned decorations into pockets
  def decorations_by_pocket
    pockets = Hash.new { |hash, key| hash[key] = {} }

    @secret_base_decorations.each do |id, qty|
      next if qty <= 0
      data = Decoration.get(id)
      next unless data

      category = data[:category]
      pockets[category][id] = qty
    end
  end

  # Returns an array of decoration IDs owned by the player
  def decorations_in_pocket(category)
    category = category.to_sym
    pocket_items = []

    @secret_base_decorations.each do |id, qty|
      next if qty <= 0
      data = Decoration.get(id)
      if data && data[:category] == category
        pocket_items.push(id)
      end
    end

    return pocket_items
  end
end