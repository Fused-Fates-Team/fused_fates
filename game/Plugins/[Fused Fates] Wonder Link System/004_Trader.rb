#================================================================================================
# Pokémon Fused Fates Wonder Link System - 004_Trader.rb
#================================================================================================

#==================================================================
# module WonderLinkTrader
#==================================================================
module WonderLinkTrader
  # Retrieves a specific Pokémon from a Wonder Link code for trading
  def self.create_trade_from_code(code, index = 0)
    if code.nil? || code.empty?
      pbMessage(_INTL("Invalid or empty Wonder Link code!"))
      return nil
    end

    # Delegate party array extraction to WonderLinkDecoder
    decoded_data = WonderLinkDecoder.decode_party_array(code)

    if decoded_data.nil? || decoded_data[:party].nil? || decoded_data[:party].empty?
      pbMessage(_INTL("The Wonder Link code contained no valid Pokémon to trade."))
      return nil
    end
    
    # Handle random selection if requested
    target_index = index == :random ? rand(decoded_data[:party].length) : index

    # Fallback to the last available Pokémon if the index is out of bounds
    target_index = [target_index, decoded_data[:party].length - 1].min
    target_index = [target_index, 0].max

    return {
      pokemon: decoded_data[:party][target_index],
      owner: decoded_data[:owner]
    }
  end

  # Initiates a trade using the clipboard data
  def self.start_trade_from_clipboard(player_party_index, wonder_party_index = 0)
    player_party = $player.party

    if player_party_index < 0 || player_party_index >= player_party.length
      pbMessage(_INTL("Invalid party Pokémon selected for trade."))
      return false
    end

    code = Input.clipboard
    trade_data = create_trade_from_code(code, wonder_party_index)

    return false unless trade_data

    incoming_pokemon = trade_data[:pokemon]

    owner_name = trade_data[:owner]
    owner_name = "Wonder Trader" if owner_name.nil?

    # Ensure the incoming Pokémon has the correct OT details
    if incoming_pokemon.respond_to?(:owner) && incoming_pokemon.owner
      incoming_pokemon.owner.name = owner_name
    end

    # Reset specific attributes if needed
    incoming_pokemon.heal

    pbStartTrade(player_party_index, incoming_pokemon, incoming_pokemon.name, owner_name)

    return true
  end
end