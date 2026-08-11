#================================================================================================
# Pokémon Fused Fates Secret Base System - 003_Decorations.rb
#================================================================================================

#==================================================================
# module Decoration
#==================================================================
module Decoration
  # Database registry for all secret base decorations
  # Format: ID => {name: "...", category: :type, graphic: "filename" }
  DECORATIONS = {
    # Dolls
    :TURTWIG_DOLL => { name: "Turtwig Doll", category: :doll, graphic: "turtwig_doll"},
    :CHIMCHAR_DOLL => { name: "Chimchar Doll", category: :doll, graphic: "chimchar_doll"},
    :PIPLUP_DOLL => { name: "Piplup Doll", category: :doll, graphic: "piplup_doll"}
  }

  # Checks if a given decoration ID is recognized as valid
  def self.exists?(id)
    return false if id.nil?
    return DECORATIONS.key?(id.to_sym)
  end

  # Retrieves the properties hash for a valid decoration ID
  def self.get(id)
    return nil unless exists?(id)
    return DECORATIONS[id.to_sym]
  end

  # Returns an array of all defined decoration identifiers
  def self.keys
    return DECORATIONS.keys
  end

  # Returns an array of all unique categories present in the database
  def self.categories
    return DECORATIONS.values.map { |data| data[:category] }.uniq
  end
  
  # Returns an array of decoration keys belonging to a specific category
  def self.keys_by_category(category)
    category = category.to_sym
    return DECORATIONS.select { |id, data| data[:category] == category }.keys
  end

  # Loads and returns a cached Bitmap for a given decoration ID
  def self.load_bitmap(id)
    data = get(id)
    return nil unless data

    category = data[:category].to_s
    graphic = data[:graphic]
    return nil if graphic.nil? || graphic.empty?

    folder = "Graphics/Decorations/#{category}/"

    begin
      return RPG::Cache.load_bitmap(folder, graphic)
    rescue
      puts "Warning: Decoration graphic not found at #{folder}#{graphic}.png"
      fallback = Bitmap.new(32, 32)
      fallback.fill_rect(0, 0, 32, 32, Color.new(255, 0, 255)) # Magenta placeholder
      return fallback
    end
  end

  def self.load_icon(id)
    return load_bitmap(id)
  end
end