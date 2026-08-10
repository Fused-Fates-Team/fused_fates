#================================================================================================
# Pokémon Fused Fates Wonder Link System - 002_Decoder.rb
#================================================================================================
require 'zlib'

#==================================================================
# module WonderLinkDecoder
#==================================================================
module WonderLinkDecoder
  # Imports and decodes a party from a Base64 compressed string in the clipboard
  def self.import_party_from_clipboard
    code = Input.clipboard
    if code.nil? || code.empty?
      pbMessage(_INTL("No Wonder Link code was found on your clipboard!"))
      return false
    end
  end

  # Parses the Base64 compressed string and returns an array of reconstructed Pokémon objects
  def self.decode_party_array(code)
    if code.nil? || code.empty?
      return nil
    end

    begin
      # Decode Base64 and Inflate the compressed binary stream
      compressed_data = Base64.strict_decode64(code)
      binary_stream = Zlib::Inflate.inflate(compressed_data)

      party = []
      offset = 0

      # Unpack the Party Owner's Name first
      owner_name_len = binary_stream.unpack("@#{offset}C").first
      offset += 1
      party_owner_name = binary_stream[offset, owner_name_len]
      offset += owner_name_len

      while offset < binary_stream.bytesize
        # Unpack Species, Level, Item ID 
        species_id, level, item_id = binary_stream.unpack("@#{offset}nCn")
        offset += 5

        # Ensure level stays within valid bounds (1 to 100)
        level = [[level, 1].max, 100].min

        # Unpack Fusion Head and Body IDs 
        f_head, f_body = binary_stream.unpack("@#{offset}nn")
        offset += 4

        # Unpack Ability ID 
        ability_id = binary_stream.unpack("@#{offset}n").first
        offset += 2

        # Unpack Moveset IDs 
        move_data = binary_stream.unpack("@#{offset}nnnn")
        offset += 8

        # Unpack IVs
        iv_data = binary_stream.unpack("@#{offset}CCCCCC")
        offset += 6

        # Unpack EVs
        ev_data = binary_stream.unpack("@#{offset}CCCCCC")
        offset += 6

        # Unpack the Pokémon's OT Name
        ot_name_len = binary_stream.unpack("@#{offset}C").first
        offset += 1
        ot_name = binary_stream[offset, ot_name_len]
        offset += ot_name_len

        # Map IDs back to symbols or valid GameData objects
        species_sym = species_id > 0 ? GameData::Species.keys[species_id] : nil        
        item_sym = item_id > 0 ? GameData::Item.keys[item_id] : nil
        ability_sym = ability_id > 0 ? GameData::Ability.keys[ability_id] : nil
        
        f_head_sym = f_head > 0 ? GameData::Species.keys[f_head] : nil
        f_body_sym = f_body > 0 ? GameData::Species.keys[f_body] : nil

        # Instantiate the Pokémon
        if f_head_sym && f_body_sym
          combined_sym = :"#{f_head_sym}_#{f_body_sym}".to_sym

          pkmn = FusedPokemon.new(combined_sym, level, f_head_sym, f_body_sym)

          # Assign fusion-specific attributes and species data
          pkmn.fusion_head = f_head_sym
          pkmn.fusion_body = f_body_sym
          pkmn.original_head_data = GameData::Species.try_get(f_head_sym)
          pkmn.original_body_data = GameData::Species.try_get(f_body_sym)

          pkmn.create_virtual_species_data if pkmn.respond_to?(:fused?)

          pkmn.calc_stats if pkmn.respond_to?(:calc_stats)
        else
          pkmn = Pokemon.new(species_sym, level)
        end

        pkmn.item = item_sym if item_sym

        # Restore Fusion configuration if supported
        if pkmn.respond_to?(:fusion_head=) && f_head_sym && f_body_sym
          pkmn.fusion_head = f_head_sym
          pkmn.fusion_body = f_body_sym
        end

        # Restore Ability
        if ability_sym && pkmn.respond_to?(:ability=)
          pkmn.ability = ability_sym
        end

        # Restore Moveset
        pkmn.reset_moves
        move_data.each do |m_id|
          next if m_id <= 0
          m_sym = GameData::Move.keys[m_id]
          pkmn.learn_move(m_sym) if m_sym
        end

        stat_keys = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]
        # Restore IVs
        stat_keys.each_with_index do |stat, idx|
          if pkmn.iv.is_a?(Hash)
            pkmn.iv[stat] = iv_data[idx]
          elsif pkmn.iv.respond_to?(:[]=)
            pkmn.iv[stat] = iv_data[idx]
          end
        end

        # Restore EVs
        stat_keys.each_with_index do |stat, idx|
          if pkmn.ev.is_a?(Hash)
            pkmn.ev[stat] = ev_data[idx]
          elsif pkmn.ev.respond_to?(:[]=)
            pkmn.ev[stat] = ev_data[idx]
          end
        end

        # Restore the OT Name
        if defined?(Pokemon::Owner) && pkmn.respond_to?(:owner) && pkmn.owner
          pkmn.owner.name = ot_name
        end

        # Unpack Nature, Form, and Personal ID
        nature_id, gender_id, form_id, personal_id = binary_stream.unpack("@#{offset}nnVC")
        offset += 9

        nature_sym = nature_id > 0 ? GameData::Nature.keys[nature_id] : nil
        pkmn.nature = nature_sym if nature_sym
        pkmn.form = form_id if pkmn.respond_to?(:form=)
        pkmn.personalID = personal_id if pkmn.respond_to?(:personalID=)
        pkmn.gender = gender_id if pkmn.respond_to?(:gender=)

        # Recalculate stats with all attributes applied
        pkmn.calc_stats
        party.push(pkmn)
      end

      return { party: party, owner: party_owner_name }

    rescue => error
      pbMessage(_INTL("An error occurred while decoding the Wonder Link code."))
      puts "Wonder Link Decode Error: #{error.message}"
      return nil
    end
  end
end