#================================================================================================
# Pokémon Fused Fates - Fusion System Scenes
#================================================================================================

class PokemonFusing_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(pkmn_head, pkmn_body)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @pkmn_head = pkmn_head
    @pkmn_body = pkmn_body
    @sprites = {}
    @sprites["headsprite"] = PokemonSprite.new(@viewport)
    @sprites["headsprite"].setOffset(PictureOrigin::CENTER)
    @sprites["headsprite"].x = 104
    @sprites["headsprite"].y = 206
    @sprites["headsprite"].setPokemonBitmap(@pkmn_head)
    @sprites["bodysprite"] = PokemonSprite.new(@viewport)
    @sprites["bodysprite"].setOffset(PictureOrigin::CENTER)
    @sprites["bodysprite"].x = 416
    @sprites["bodysprite"].y = 206
    @sprites["bodysprite"].setPokemonBitmap(@pkmn_body)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartFusionAnimation(pkmn_head, pkmn_body)
    # Bring sprites to the center to initiate collision
    frames = 60
    dist_x = (Graphics.width / 2) - @sprites["headsprite"].x
    dist_y = (Graphics.height / 2) - @sprites["headsprite"].y

    frames.times do |i|
      @sprites["headsprite"].x += dist_x / frames
      @sprites["headsprite"].y += dist_y / frames
      @sprites["bodysprite"].x -= dist_x / frames
      @sprites["bodysprite"].y += dist_y / frames
      pbUpdate
      Graphics.update
    end

    # Flash effect to signify the merging
    @viewport.flash(Color.new(255, 255, 255), 20)
  end

  def pbEndFusionAnimation(fused_pkmn)
    # Dispose individual parents
    @sprites["headsprite"].dispose
    @sprites["bodysprite"].dispose

    # Create the new fused sprite
    @sprites["fusedsprite"] = PokemonSprite.new(@viewport)
    @sprites["fusedsprite"].setOffset(PictureOrigin::CENTER)
    @sprites["fusedsprite"].x = Graphics.width / 2
    @sprites["fusedsprite"].y = Graphics.height / 2
    @sprites["fusedsprite"].setPokemonBitmap(fused_pkmn)

    # Final fade in
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end