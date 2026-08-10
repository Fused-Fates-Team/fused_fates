#================================================================================================
# Pokémon Fused Fates Wonder Link System - 001_Encoder.rb
#================================================================================================
require 'zlib'

#==================================================================
# module WonderLinkEncoder
#==================================================================
module WonderLinkEncoder
  # Exports the player's current party to the clipboard as a compressed Base64 string
  def self.export_party_to_clipboard
    # Isolate the Data
    party = $player.party

    if party.empty?
      pbMessage(_INTL("You don't have any Pokémon in your party to export!"))
      return false
    end

    begin
      binary_stream = ""

      # Pack the Party Owner's Name
      owner_name = $player.name rescue "Unknown"
      binary_stream << [owner_name.bytesize].pack("C")
      binary_stream << owner_name

      # Build a lightweight, compact array of hashes containing only essential data
      party.map do |pkmn|
        raw_species = pkmn.respond_to?(:species) ? pkmn.species : 0
        species_sym = case raw_species
        when Symbol
          raw_species
        when String
          raw_species.to_sym
        when Integer
          raw_species > 0 ? (GameData::Species.keys[raw_species] || :BULBASAUR) : :BULBASAUR
        else
          GameData::Species.try_get(raw_species)&.id || :BULBASAUR
        end
        species = GameData::Species.keys.index(species_sym) || 0

        level = pkmn.level.is_a?(Integer) ? pkmn.level : 1

        raw_item = pkmn.respond_to?(:item) ? pkmn.item : nil
        item_sym = case raw_item
        when Symbol
          raw_item
        when String
          raw_item.to_sym
        when Integer
          raw_item > 0 ? (GameData::Item.keys[raw_item] || 0) : 0
        else
          raw_item ? (GameData::Item.try_get(raw_item)&.id || 0) : 0
        end
        item = item_sym == 0 ? 0 : (GameData::Item.keys.index(item_sym) || 0)

        # Pack Species, Level, and Item ID 
        binary_stream << [species, level, item].pack("nCn")

        # Fusion IDs if applicable 
        raw_f_head = pkmn.respond_to?(:fusion_head) ? pkmn.fusion_head : 0
        f_head_sym = case raw_f_head
        when Symbol
          raw_f_head
        when String
          raw_f_head.to_sym
        when Integer
          raw_f_head > 0 ? (GameData::Species.keys[raw_f_head] || 0) : 0
        else
          raw_f_head ? (GameData::Species.try_get(raw_f_head)&.id || 0) : 0
        end
        f_head = f_head_sym == 0 ? 0 : (GameData::Species.keys.index(f_head_sym) || 0)

        raw_f_body = pkmn.respond_to?(:fusion_body) ? pkmn.fusion_body : 0
        f_body_sym = case raw_f_body
        when Symbol
          raw_f_body
        when String
          raw_f_body.to_sym
        when Integer
          raw_f_body > 0 ? (GameData::Species.keys[raw_f_body] || 0) : 0
        else
          raw_f_body ? (GameData::Species.try_get(raw_f_body)&.id || 0) : 0
        end
        f_body = f_body_sym == 0 ? 0 : (GameData::Species.keys.index(f_body_sym) || 0)

        binary_stream << [f_head, f_body].pack("nn")

        # Ability serialization
        raw_ability = pkmn.respond_to?(:ability) ? pkmn.ability : nil
        ability_sym = case raw_ability
        when Symbol
          raw_ability
        when String
          raw_ability.to_sym
        when Integer
          raw_ability > 0 ? (GameData::Ability.keys[raw_ability] || 0) : 0
        else
          raw_ability ? (GameData::Ability.try_get(raw_ability)&.id || 0) : 0
        end
        ability = ability_sym == 0 ? 0 : (GameData::Ability.keys.index(ability_sym) || 0)
        binary_stream << [ability].pack("n")

        # Moveset serialization
        move_ids = []
        4.times do |i|
          move = pkmn.moves[i]
          raw_move = move ? move.id : 0
          move_sym = case raw_move
          when Symbol
            raw_move
          when String
            raw_move.to_sym
          when Integer
            raw_move > 0 ? (GameData::Move.keys[raw_move] || 0) : 0
          else
            raw_move ? (GameData::Move.try_get(raw_move)&.id || 0) : 0
          end
          move_ids << (move_sym == 0 ? 0 : (GameData::Move.keys.index(move_sym) || 0))
        end
        binary_stream << move_ids.pack("nnnn")

        # IVs packed
        iv_hash = pkmn.iv
        ivs = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].map do |stat|
          if iv_hash.is_a?(Hash)
            iv_hash[stat] || 0
          else
            31
          end
        end
        binary_stream << ivs.pack("CCCCCC")

        # EVs packed
        ev_hash = pkmn.ev
        evs = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].map do |stat|
          if ev_hash.is_a?(Hash)
            ev_hash[stat] || 0
          else
            0
          end
        end
        binary_stream << evs.pack("CCCCCC")

        # Pack the Pokémon's OT Name
        ot_name = ""
        if pkmn.respond_to?(:owner) && pkmn.owner
          ot_name = pkmn.owner.name || owner_name
        else
          ot_name = owner_name
        end

        binary_stream << [ot_name.bytesize].pack("C")
        binary_stream << ot_name

        # Nature 
        raw_nature = pkmn.respond_to?(:nature) ? pkmn.nature : nil
        nature_sym = case raw_nature
        when Symbol
          raw_nature
        when String
          raw_nature.to_sym
        when Integer
          raw_nature > 0 ? (GameData::Nature.keys[raw_nature] || 0) : 0
        else
          raw_nature ? (GameData::Nature.try_get(raw_nature)&.id || 0) : 0
        end
        nature_id = nature_sym == 0 ? 0 : (GameData::Nature.keys.index(nature_sym) || 0)

        # Form
        form_id = pkmn.respond_to?(:form) ? (pkmn.form || 0) : 0

        # Personal ID
        personal_id = pkmn.respond_to?(:personalID) ? (pkmn.personalID || 0) : 0

        # Pack Nature, Form, and Personal ID
        binary_stream << [nature_id, form_id, personal_id].pack("nnV")
      end

      # Compress the Data
      # Shrinks the massive byte size of a 6-slot fused party
      compressed_data = Zlib::Deflate.deflate(binary_stream, Zlib::BEST_COMPRESSION)

      # Encode the Data
      wonder_link_code = Base64.strict_encode64(compressed_data)
      
      # Copy to Clipboard
      Input.clipboard = wonder_link_code

      pbMessage(_INTL("Your Wonder Link code has been copied to your clipboard!"))
      return true

    rescue => error
      # Safety wrapper to prevent crashes during the export process
      pbMessage(_INTL("An error occurred while generating your Wonder Link code."))
      puts "Wonder Link Export Error: #{error.message}"
      return false
    end
  end
end