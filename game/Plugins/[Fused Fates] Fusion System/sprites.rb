#================================================================================================
# Pokémon Fused Fates Fusion System - sprites
#================================================================================================

#================================================================
# module FusionSpriteLoader
#================================================================
module FusionSpriteLoader
  def self.get_fusion_bitmap(head_species, body_species)
    head_data = GameData::Species.get(head_species)
    body_data = GameData::Species.get(body_species)

    # Check if a custom sprite exists first
    filename = sprintf("Graphics/Pokemon/Fusion/%s_%s", head_data.id_number, body_data.id_number)
    if RPG::Cache.retain(filename)
      return AnimatedBitmap.new(filename)
    end

    # Procedural split slicing (Top half head, bottom half body)
    body_bitmap = GameData::Species.sprite_bitmap(body_species)
    head_bitmap = GameData::Species.sprite_bitmap(head_species)

    result_bitmap = Bitmap.new(body_bitmap.width, body_bitmap.height)

    # Copy bottom
    src_rect = Rect.new(0, result_bitmap.height / 2, result_bitmap.width, result_bitmap.height / 2)
    result_bitmap.blt(0, result_bitmap.height / 2, body_bitmap, src_rect)

    # Copy top
    src_rect_head = Rect.new(0, 0, result_bitmap.width, result_bitmap.height / 2)
    result_bitmap.blt(0, 0, head_bitmap, src_rect_head)

    head_bitmap.dispose
    body_bitmap.dispose

    return result_bitmap
  end
end